terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.0" 
    }
  }

  # Uncomment the following backend configuration block AFTER the `azurerm_storage_account.tfstate`
  # and `azurerm_storage_container.tfstate` resources have been successfully created.
  # Replace the placeholder values with the actual names of the resource group,
  # storage account, and container that Terraform will use to store its state.
  # This block CANNOT use Terraform expressions (like `azurerm_resource_group.main.name`)
  # as backend configuration must be known before Terraform initializes.
  /*
  backend "azurerm" {
    resource_group_name  = "your-tfstate-resource-group-name"
    storage_account_name = "yourtfstatestorageaccountname"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
  */
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Resources for Terraform state backend
resource "random_id" "tfstate_suffix" {
  byte_length = 8
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "tfstate${random_id.tfstate_suffix.hex}" # Unique name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "GRS" # Geo-Redundant Storage for high durability
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}
