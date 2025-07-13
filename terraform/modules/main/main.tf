module "cosmosdb" {
  source = "../cosmosdb"
  resource_group_name                = var.resource_group_name
  location                           = var.location
  cosmosdb_account_name              = var.cosmosdb_account_name
  kind                               = var.kind
  consistency_level                  = var.consistency_level
  cosmosdb_sql_database_name         = var.cosmosdb_sql_database_name
  cosmosdb_sql_database_throughput   = var.cosmosdb_sql_database_throughput
  cosmosdb_sql_containers            = var.cosmosdb_sql_containers
}

module "storage" {
  source = "../storage"
  resource_group_name                = var.resource_group_name
  location                           = var.location
  storage_account_name               = var.storage_account_name
  storage_account_tier               = var.storage_account_tier
  storage_account_replication_type   = var.storage_account_replication_type
  storage_containers                 = var.storage_containers
}

module "redis" {
  source = "../redis"
  resource_group_name                = var.resource_group_name
  location                           = var.location
  redis_cache_name                   = var.redis_cache_name
  redis_cache_capacity               = var.redis_cache_capacity
  redis_cache_family                 = var.redis_cache_family
  redis_cache_sku_name               = var.redis_cache_sku_name
  redis_cache_enable_non_ssl_port    = var.redis_cache_enable_non_ssl_port
  redis_cache_configuration          = var.redis_cache_configuration
}
