# main.tf
# This file serves as the entry point for the Terraform configuration.
# It defines the required Terraform providers, configures the Azure provider,
# and sets up the main resource group and the backend for storing Terraform state.

# Terraform Configuration Block
# Specifies the required Terraform version and providers.
terraform {
  # Defines the required providers and their versions.
  required_providers {
    # Specifies the AzureRM provider.
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Constrains the provider version to avoid breaking changes.
    }
  }

  # Backend Configuration for storing Terraform state in Azure Storage.
  # This block is commented out initially. It should be uncommented and configured
  # AFTER the Azure Storage Account and Container for state are created.
  # Backend configuration cannot use Terraform expressions because it needs to be
  # known before Terraform initializes and evaluates expressions.
  /*
  backend "azurerm" {
    # The name of the resource group where the tfstate storage account is located.
    resource_group_name  = "your-tfstate-resource-group-name"
    # The name of the Azure Storage Account used for storing Terraform state.
    storage_account_name = "yourtfstatestorageaccountname"
    # The name of the container within the storage account to store the tfstate file.
    container_name       = "tfstate"
    # The path to the tfstate file within the container.
    key                  = "terraform.tfstate"
  }
  */
}

# Azure Provider Configuration
# Configures the AzureRM provider with default settings.
provider "azurerm" {
  # The 'features' block is required but can be empty for default settings.
  features {}
}

# Main Resource Group
# Defines the primary Azure Resource Group where all other resources will be deployed.
resource "azurerm_resource_group" "main" {
  # The name of the resource group.
  name     = var.resource_group_name
  # The Azure region where the resource group will be located.
  location = var.location
}

# Resources for Terraform state backend
# These resources are for setting up the Azure Storage Account and Container
# to store the Terraform state file remotely.

# Generates a random suffix to ensure the storage account name is globally unique.
resource "random_id" "tfstate_suffix" {
  byte_length = 8 # Generates 8 random bytes, which results in 16 hex characters.
}

# Storage Account for Terraform state
resource "azurerm_storage_account" "tfstate" {
  # Name of the storage account, made unique with a random suffix.
  name                     = "tfstate${random_id.tfstate_suffix.hex}" # Unique name
  # The resource group where the storage account will be deployed.
  resource_group_name      = azurerm_resource_group.main.name
  # The Azure region where the storage account will be deployed.
  location                 = azurerm_resource_group.main.location
  # Tier of the storage account (e.g., "Standard", "Premium").
  account_tier             = "Standard"
  # Replication type for the storage account (e.g., "LRS", "GRS", "RA-GRS").
  # GRS (Geo-Redundant Storage) provides high durability by replicating data to a secondary region.
  account_replication_type = "GRS" # Geo-Redundant Storage for high durability
  # Minimum TLS version required for connections to the storage account.
  min_tls_version          = "TLS1_2"
}

# Storage Container for Terraform state
resource "azurerm_storage_container" "tfstate" {
  # Name of the container where the Terraform state file will be stored.
  name                  = "tfstate"
  # The storage account where this container will be created.
  storage_account_name  = azurerm_storage_account.tfstate.name
  # Access type for the container (e.g., "private", "blob", "container").
  container_access_type = "private"
}