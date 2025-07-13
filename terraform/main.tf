terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116.0" 
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

module "cosmosdb" {
  source                        = "./modules/cosmosdb"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  cosmosdb_account_name         = var.cosmosdb_account_name
  kind                          = var.cosmosdb_kind
  consistency_level             = var.cosmosdb_consistency_level
  cosmosdb_sql_database_name    = var.cosmosdb_sql_database_name
  cosmosdb_sql_database_throughput = var.cosmosdb_sql_database_throughput
  billing_container_name        = var.billing_container_name
  billing_partition_key         = var.billing_partition_key
}

module "storage" {
  source                        = "./modules/storage"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  storage_account_name          = var.storage_account_name
  storage_account_tier          = var.storage_account_tier
  storage_account_replication_type = var.storage_account_replication_type
  storage_containers            = var.storage_containers
}

module "redis" {
  source                        = "./modules/redis"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  redis_cache_name              = var.redis_cache_name
  redis_cache_capacity          = var.redis_cache_capacity
  redis_cache_family            = var.redis_cache_family
  redis_cache_sku_name          = var.redis_cache_sku_name
  redis_cache_enable_non_ssl_port = var.redis_cache_enable_non_ssl_port
  redis_cache_configuration     = var.redis_cache_configuration
}


resource "azurerm_data_factory" "billing_adf" {
  name                = var.data_factory_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}



