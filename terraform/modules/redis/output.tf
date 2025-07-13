output "redis_connection_string" {
  value     = azurerm_redis_cache.redis.primary_connection_string
  sensitive = true
}