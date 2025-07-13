resource "azurerm_redis_cache" "redis_cache" {
  name                = var.redis_cache_name
  resource_group_name = var.resource_group_name
  location            = var.location
  capacity            = var.redis_cache_capacity
  family              = var.redis_cache_family
  sku_name            = var.redis_cache_sku_name
  enable_non_ssl_port = var.redis_cache_enable_non_ssl_port
  redis_configuration {
    maxmemory_policy = var.redis_cache_configuration.maxmemory_policy
  }
}