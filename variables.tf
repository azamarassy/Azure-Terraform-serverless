# variables.tf for Azure

variable "domain_name" {
  description = "The main domain name for the application."
  type        = string
  default     = "example.com"
}

variable "location" {
  description = "The Azure region where resources will be deployed."
  type        = string
  default     = "japaneast"
}

variable "resource_group_name" {
  description = "The name of the resource group to create."
  type        = string
  default     = "rg-serverless-app"
}

variable "storage_account_name" {
  description = "The name of the Azure Storage Account for static website hosting."
  type        = string
  default     = "staticwebsiteappstorage" # Must be globally unique, lowercase, no special characters
}

variable "function_app_name" {
  description = "The name of the Azure Function App."
  type        = string
  default     = "func-serverless-app"
}

variable "api_management_service_name" {
  description = "The name of the Azure API Management service."
  type        = string
  default     = "apim-serverless-app"
}

variable "front_door_name" {
  description = "The name of the Azure Front Door profile."
  type        = string
  default     = "afd-serverless-app"
}
