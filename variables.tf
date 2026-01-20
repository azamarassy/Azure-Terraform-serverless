# variables.tf
# This file defines the input variables for the Terraform configuration.
# Variables allow for parameterizing the deployment, making it more flexible
# and reusable across different environments or projects.

# Variable: Domain Name
# The primary domain name for the application. This will be used for configuring DNS records.
variable "domain_name" {
  description = "The main domain name for the application."
  type        = string
  default     = "example.com" # Default value, can be overridden during Terraform execution.
}

# Variable: Azure Region
# The Azure region where the majority of the resources will be deployed.
variable "location" {
  description = "The Azure region where resources will be deployed."
  type        = string
  default     = "japaneast" # Default to Japan East, can be changed.
}

# Variable: Resource Group Name
# The name of the Azure Resource Group that will contain all the deployed resources.
variable "resource_group_name" {
  description = "The name of the resource group to create."
  type        = string
  default     = "rg-serverless-app" # Default name for the resource group.
}

# Variable: Storage Account Name for Static Website
# The name of the Azure Storage Account used for hosting the static website.
# This name must be globally unique across Azure and adhere to naming conventions (lowercase, no special characters).
variable "storage_account_name" {
  description = "The name of the Azure Storage Account for static website hosting."
  type        = string
  default     = "staticwebsiteappstorage" # Must be globally unique, lowercase, no special characters
}

# Variable: Azure Function App Name
# The name of the Azure Function App that will host the backend logic.
variable "function_app_name" {
  description = "The name of the Azure Function App."
  type        = string
  default     = "func-serverless-app" # Default name for the Function App.
}

# Variable: API Management Service Name
# The name of the Azure API Management service instance.
variable "api_management_service_name" {
  description = "The name of the Azure API Management service."
  type        = string
  default     = "apim-serverless-app" # Default name for the API Management service.
}

# Variable: Front Door Profile Name
# The name of the Azure Front Door profile.
variable "front_door_name" {
  description = "The name of the Azure Front Door profile."
  type        = string
  default     = "afd-serverless-app" # Default name for the Front Door profile.
}

# Variable: Azure Function App Log Level
# The logging level for the Azure Function App.
variable "log_level" {
  description = "The log level for the Azure Function App."
  type        = string
  default     = "INFO" # Common log levels include "INFO", "WARNING", "ERROR", "DEBUG".
}