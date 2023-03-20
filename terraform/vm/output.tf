# Get the IP address
output "vm_ip_addr" {
  value = azurerm_public_ip.pip.ip_address
  sensitive = false
}

# Get the VM password
output "vm_secret" {
  value = data.azurerm_key_vault_secret.secret.value
  sensitive = true
}