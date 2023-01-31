output "resource_group_name" {
  value       = azurerm_resource_group.tfstate.name
  description = "Boostrap Resource Group"
}
