output "cosmosdb_endpoint" {
  value = azurerm_cosmosdb_account.cosmosdb_account.endpoint
}
output "cosmosdb_primary_key" {
  value     = azurerm_cosmosdb_account.cosmosdb_account.primary_key
  sensitive = true
}