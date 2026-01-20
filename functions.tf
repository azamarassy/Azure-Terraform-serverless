# functions.tf

# 1. Storage Account for Azure Functions
resource "azurerm_storage_account" "functions" {
  name                     = "${var.function_app_name}sa" # Unique name needed
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 2. Application Insights for monitoring
resource "azurerm_application_insights" "app_insights" {
  name                = "${var.function_app_name}-appinsights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
}

# 3. Consumption App Service Plan
resource "azurerm_service_plan" "functions_plan" {
  name                = "${var.function_app_name}-plan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption Plan for Linux
}

# 4. Azure Function App
resource "azurerm_function_app" "backend_function_app" {
  name                       = var.function_app_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  app_service_plan_id        = azurerm_service_plan.functions_plan.id
  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key
  version                    = "~3" # Python runtime version (e.g., Python 3.9) - check Azure docs for exact string

  # For Python functions
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.app_insights.connection_string
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false" # Important for Consumption Plan, ensures code is run from package
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true" # For building from package
    "LOG_LEVEL" = var.log_level
  }

  site_config {
    linux_fx_version = "PYTHON|3.9" # Specify Python 3.9
  }

  identity {
    type = "SystemAssigned" # Enable Managed Identity for the Function App
  }
}
