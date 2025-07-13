variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "cosmosdb_account_name" { type = string }
variable "kind" { type = string }
variable "consistency_level" { type = string }
variable "cosmosdb_sql_database_name" { type = string }
variable "cosmosdb_sql_database_throughput" { type = number }
variable "cosmosdb_sql_containers" {
  type = list(object({
    name               = string
    partition_key_path = string
    throughput         = number
  }))
}