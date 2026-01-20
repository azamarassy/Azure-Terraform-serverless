# apimanagement.tf

# 1. API Management Service
resource "azurerm_api_management" "apim_service" {
  name                = var.api_management_service_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  publisher_name      = "My Company" # Replace with your publisher name
  publisher_email     = "admin@example.com" # Replace with your email

  sku_name = "Developer_1" # Basic SKU for development. Choose appropriate for production.

  identity {
    type = "SystemAssigned" # Enable Managed Identity for API Management
  }
}

# 2. API: Representing our backend service
resource "azurerm_api_management_api" "backend_api" {
  name                = "BackendAPI"
  resource_group_name = azurerm_resource_group.main.name
  api_management_name = azurerm_api_management.apim_service.name
  revision            = "1" # Revision for the API
  display_name        = "Backend API"
  path                = "api" # Base path for this API (e.g., /api/data)
  protocols           = ["https"]
  service_url         = azurerm_function_app.backend_function_app.default_hostname # Points to the Function App hostname
  description         = "API to interact with the backend Azure Function."
}

# API Policy for Backend API
resource "azurerm_api_management_api_policy" "backend_api_policy" {
  api_name            = azurerm_api_management_api.backend_api.name
  api_management_name = azurerm_api_management.apim_service.name
  resource_group_name = azurerm_resource_group.main.name

  xml_content = <<-XML
    <policies>
      <inbound>
        <base />
        <set-backend-service base-url="https://${azurerm_function_app.backend_function_app.default_hostname}/api" />
        <rewrite-uri template="@(context.Request.Url.Path.ToString().Replace("/api", "/"))" />
      </inbound>
      <backend>
        <base />
      </backend>
      <outbound>
        <base />
      </outbound>
      <on-error>
        <base />
      </on-error>
    </policies>
  XML
}

# 3. API Operation for /data (GET)
resource "azurerm_api_management_api_operation" "get_data_operation" {
  api_management_name = azurerm_api_management.apim_service.name
  api_name            = azurerm_api_management_api.backend_api.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Get Data"
  method              = "GET"
  url_template        = "/data" # This will map to /api/data
  description         = "Retrieves data from the backend."

  response {
    status_code = 200
    description = "Successful response"
  }
}

# 4. Product to manage API access and subscriptions
resource "azurerm_api_management_product" "starter_product" {
  product_id          = "starter"
  api_management_name = azurerm_api_management.apim_service.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Starter"
  subscription_required = true
  approval_required   = false
  published           = true
}

# Link the API to the Product
resource "azurerm_api_management_product_api" "product_api_link" {
  product_id          = azurerm_api_management_product.starter_product.product_id
  api_name            = azurerm_api_management_api.backend_api.name
  api_management_name = azurerm_api_management.apim_service.name
  resource_group_name = azurerm_resource_group.main.name
}

# 5. Subscription (API Key) for the product
resource "azurerm_api_management_subscription" "product_subscription" {
  api_management_name = azurerm_api_management.apim_service.name
  resource_group_name = azurerm_resource_group.main.name
  product_id          = azurerm_api_management_product.starter_product.product_id
  display_name        = "StarterSubscription"
  user_id             = "576a81577740e21a240656a7" # Built-in 'admin' user ID for API Management
  state = "active"
}
