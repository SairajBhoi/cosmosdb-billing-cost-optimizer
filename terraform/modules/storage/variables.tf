variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "storage_account_name" { type = string }
variable "account_tier" { type = string }
variable "account_replication_type" { type = string }
variable "containers" {
  type = list(object({
    name        = string
    access_type = string
  }))
}