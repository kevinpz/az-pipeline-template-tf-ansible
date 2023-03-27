# Create a public IP
resource "azurerm_public_ip" "pip" {
  name                = "pip-terraform-ansible"
  resource_group_name = var.rg_name
  location            = var.location
  allocation_method   = "Static"
}

# Create a NIC
resource "azurerm_network_interface" "nic" {
  name                = "nic-terraform-ansible"
  location            = var.location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# Get an existing keyvault
data "azurerm_key_vault" "kv" {
  name                = var.kv_name
  resource_group_name = var.kv_rg_name
}

# Get an existing secret
data "azurerm_key_vault_secret" "secret" {
  name         = var.kv_secret_name
  key_vault_id = data.azurerm_key_vault.kv.id
}

# Create a VM
resource "azurerm_linux_virtual_machine" "packer" {
  name                = var.vm_name
  resource_group_name = var.rg_name
  location            = var.location

  size                = "Standard_B1s"
  admin_username      = "adminuser"
  disable_password_authentication = false
  admin_password = data.azurerm_key_vault_secret.secret.value

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}

resource "null_resource" "ansible" {

  triggers {
    key = "${uuid()}"
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u adminuser -i '${azurerm_public_ip.pip.ip_address},' --extra-vars 'ansible_password=${data.azurerm_key_vault_secret.secret.value}' '../../az-server/${var.ansible_playbook}'"
  }

  depends_on = [
    azurerm_linux_virtual_machine.packer
  ]
}