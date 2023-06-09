# Create a public IP
resource "azurerm_public_ip" "pip" {
  name                = "pip-${var.vm_name}"
  resource_group_name = var.rg_name
  location            = var.location
  allocation_method   = "Static"
}

# Create a NIC
resource "azurerm_network_interface" "nic" {
  name                = "nic-${var.vm_name}"
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

# Call ansible
resource "null_resource" "ansible" {

  # Only if we specify an ansible playbook
  count = var.ansible_playbook == "" ? 0 : 1

  # Force ansible to run each time the playbook file is modified
  triggers = {
    key = "${filemd5("../../az-server/${var.ansible_playbook}")}"
  }

  # Wait for the SSH to become available
  provisioner "remote-exec" {
    connection {
      host = azurerm_public_ip.pip.ip_address
      user = "adminuser"
      password = data.azurerm_key_vault_secret.secret.value
    }

    inline = ["echo 'SSH is running!'"]
  }

  # Then call ansible with the playbook
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u adminuser -i '${azurerm_public_ip.pip.ip_address},' --extra-vars \"ansible_password=$vm_password\" '../../az-server/${var.ansible_playbook}'"
    environment = {
      vm_password = nonsensitive(data.azurerm_key_vault_secret.secret.value)
    }
  }

  # Depends on the VM creation
  depends_on = [
    azurerm_linux_virtual_machine.packer
  ]
}