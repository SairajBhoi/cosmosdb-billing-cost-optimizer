resource "azurerm_cosmosdb_account" "cosmosdb_account" {
  # Cosmos DB account for billing records
  name                = var.cosmosdb_account_name
  resource_group_name = var.resource_group_name
  location            = var.location
  offer_type          = var.offer_type
  kind                = var.kind
  consistency_policy {
    consistency_level = var.consistency_level
  }
  geo_location {
    location          = var.location
    failover_priority = var.failover_priority
  }
  tags                = var.tags
}

resource "azurerm_cosmosdb_sql_database" "cosmosdb_sql_database" {
  # Cosmos DB SQL database for billing
  name                = var.cosmosdb_sql_database_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmosdb_account.name
  throughput          = var.cosmosdb_sql_database_throughput
  tags                = var.tags
}

resource "azurerm_cosmosdb_sql_container" "cosmosdb_sql_container" {
  # Container for hot billing data (last 90 days)
  name                = var.billing_container_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmosdb_account.name
  database_name       = azurerm_cosmosdb_sql_database.cosmosdb_sql_database.name
  partition_key_path  = var.billing_partition_key
  throughput          = var.cosmosdb_sql_database_throughput
  tags                = var.tags
}