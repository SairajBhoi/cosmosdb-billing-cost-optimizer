output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}
output "storage_account_primary_connection_string" {
  value     = azurerm_storage_account.storage.primary_connection_string
  sensitive = true
}