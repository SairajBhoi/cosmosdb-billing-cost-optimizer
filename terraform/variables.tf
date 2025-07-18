variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group"
  default     = "billing-management-rg"
}

variable "location" {
  type        = string
  description = "Azure region for resource deployment"
  default     = "East US"
}

variable "cosmos_db_account_name" {
  type        = string
  description = "Name of the Azure Cosmos DB account"
  default     = "billing-cosmos-db"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the Azure Storage account (must be globally unique, 3-24 chars, lowercase)"
}



variable "function_app_archive_name" {
  type        = string
  description = "Name of the Azure Function App for archiving"
  default     = "billing-archive-func"
}

