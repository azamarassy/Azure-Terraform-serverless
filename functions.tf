# functions.tf
# This file defines the Azure Function App and its supporting resources,
# including a Storage Account, Application Insights for monitoring, and an App Service Plan.
# Azure Function Apps provide serverless compute capabilities.

# 1. Storage Account for Azure Functions
# Azure Function Apps require a storage account to manage triggers and log function executions.
resource "azurerm_storage_account" "functions" {
  # Name of the storage account. Must be globally unique.
  name                     = "${var.function_app_name}sa" # Unique name needed
  # The resource group in which to create the storage account.
  resource_group_name      = azurerm_resource_group.main.name
  # The Azure region where the storage account will be deployed.
  location                 = azurerm_resource_group.main.location
  # Tier of the storage account (e.g., "Standard", "Premium").
  account_tier             = "Standard"
  # Replication type for the storage account (e.g., "LRS", "GRS", "RA-GRS").
  account_replication_type = "LRS"
}

# 2. Application Insights for monitoring
# Application Insights is an Application Performance Management (APM) service for monitoring live web applications.
resource "azurerm_application_insights" "app_insights" {
  # Name of the Application Insights resource.
  name                = "${var.function_app_name}-appinsights"
  # The Azure region where Application Insights will be deployed.
  location            = azurerm_resource_group.main.location
  # The resource group in which to create the Application Insights resource.
  resource_group_name = azurerm_resource_group.main.name
  # Type of the application being monitored (e.g., "web", "other").
  application_type    = "web"
}

# 3. Consumption App Service Plan
# Defines the hosting plan for the Azure Function App.
# A Consumption plan automatically scales and you only pay for the compute resources consumed.
resource "azurerm_service_plan" "functions_plan" {
  # Name of the App Service Plan.
  name                = "${var.function_app_name}-plan"
  # The Azure region where the App Service Plan will be deployed.
  location            = azurerm_resource_group.main.location
  # The resource group in which to create the App Service Plan.
  resource_group_name = azurerm_resource_group.main.name
  # Operating system type for the App Service Plan (e.g., "Windows", "Linux").
  os_type             = "Linux"
  # SKU determines the pricing tier and capabilities of the plan. "Y1" is for Consumption.
  sku_name            = "Y1" # Consumption Plan for Linux
}

# 4. Azure Function App
# Defines the Azure Function App where serverless code will run.
resource "azurerm_function_app" "backend_function_app" {
  # Name of the Function App.
  name                       = var.function_app_name
  # The Azure region where the Function App will be deployed.
  location                   = azurerm_resource_group.main.location
  # The resource group in which to create the Function App.
  resource_group_name        = azurerm_resource_group.main.name
  # ID of the App Service Plan where the Function App will run.
  app_service_plan_id        = azurerm_service_plan.functions_plan.id
  # Name of the associated storage account.
  storage_account_name       = azurerm_storage_account.functions.name
  # Access key for the associated storage account.
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key
  # Runtime version for the Function App.
  version                    = "~3" # Python runtime version (e.g., Python 3.9) - check Azure docs for exact string

  # Application settings for the Function App.
  app_settings = {
    # Specifies the worker runtime for the function (e.g., "python", "dotnet").
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    # Connection string for Application Insights for monitoring.
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.app_insights.connection_string
    # Important for Consumption Plan: ensures code is run directly from the deployment package.
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false" # Important for Consumption Plan, ensures code is run from package
    # Enables building during deployment, useful for dependencies.
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true" # For building from package
    # Sets the logging level for the function app.
    "LOG_LEVEL" = var.log_level
  }

  # Site configuration settings for the Function App.
  site_config {
    # Specifies the Linux FX version, including the Python runtime.
    linux_fx_version = "PYTHON|3.9" # Specify Python 3.9
  }

  # Configuration for the Managed Identity of the Function App.
  identity {
    # Type of Managed Service Identity. "SystemAssigned" means Azure automatically manages the identity.
    type = "SystemAssigned" # Enable Managed Identity for the Function App
  }
}