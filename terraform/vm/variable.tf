# Location to deploy the validation VM
variable "location" {
  type = string
}

# RG name
variable "rg_name" {
  type = string
}

# ID of the submet
variable "vm_name" {
  type = string
}

# ID of the submet
variable "subnet_id" {
  type = string
}

# Keyvault RG name
variable "kv_rg_name" {
  type = string
}

# Keyvault name
variable "kv_name" {
  type = string
}

# Name of the secret
variable "kv_secret_name" {
  type = string
}

# Main ansible playbook
variable "ansible_playbook" {
  type    = string
  default = ""
}