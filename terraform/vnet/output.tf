# Get the subnet ID
output "subnet_id" {
  value = azurerm_subnet.subnet.id
  sensitive = false
}