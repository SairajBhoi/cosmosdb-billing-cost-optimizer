variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "name" { type = string }
variable "capacity" { type = number }
variable "family" { type = string }
variable "sku_name" { type = string }
variable "enable_non_ssl_port" { type = bool }
variable "redis_configuration" {
  type = object({
    maxmemory_policy = string
  })
}