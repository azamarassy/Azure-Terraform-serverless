# apimanagement.tf
# This file defines the Azure API Management (APIM) service, including its APIs,
# operations, policies, products, and subscriptions. APIM acts as a facade
# to manage, secure, and publish APIs.

# 1. API Management Service
# Defines the main Azure API Management service instance.
resource "azurerm_api_management" "apim_service" {
  # The name of the API Management service.
  name                = var.api_management_service_name
  # The Azure region where the APIM service will be deployed.
  location            = azurerm_resource_group.main.location
  # The resource group in which to create the API Management service.
  resource_group_name = azurerm_resource_group.main.name
  # The name of the API publisher.
  publisher_name      = "My Company" # Replace with your publisher name
  # The email address of the API publisher.
  publisher_email     = "admin@example.com" # Replace with your email

  # The SKU (pricing tier and capacity) of the API Management service.
  # "Developer_1" is suitable for development and testing. Choose an appropriate SKU for production.
  sku_name = "Developer_1" # Basic SKU for development. Choose appropriate for production.

  # Configuration for the Managed Identity of the API Management service.
  identity {
    # Type of Managed Service Identity. "SystemAssigned" means Azure automatically manages the identity.
    type = "SystemAssigned" # Enable Managed Identity for API Management
  }
}

# 2. API: Representing our backend service
# Defines an API within the API Management service, acting as an interface to a backend service.
resource "azurerm_api_management_api" "backend_api" {
  # The name of the API as it appears in API Management.
  name                = "BackendAPI"
  # The resource group containing the API Management service.
  resource_group_name = azurerm_resource_group.main.name
  # The name of the parent API Management service.
  api_management_name = azurerm_api_management.apim_service.name
  # The revision number of the API.
  revision            = "1" # Revision for the API
  # A user-friendly display name for the API.
  display_name        = "Backend API"
  # The base URL path for this API (e.g., requests to /api/data).
  path                = "api" # Base path for this API (e.g., /api/data)
  # The protocols clients can use to access the API (e.g., "https").
  protocols           = ["https"]
  # The URL of the backend service that this API will proxy to (e.g., an Azure Function App hostname).
  service_url         = azurerm_function_app.backend_function_app.default_hostname # Points to the Function App hostname
  # A description of the API.
  description         = "API to interact with the backend Azure Function."
}

# API Policy for Backend API
# Defines a policy that applies to the entire API, such as URL rewriting or authentication.
resource "azurerm_api_management_api_policy" "backend_api_policy" {
  # The name of the API to which this policy applies.
  api_name            = azurerm_api_management_api.backend_api.name
  # The name of the parent API Management service.
  api_management_name = azurerm_api_management.apim_service.name
  # The resource group containing the API Management service.
  resource_group_name = azurerm_resource_group.main.name

  # The XML content of the policy. This example rewrites the URL to target an Azure Function.
  xml_content = <<-XML
    <policies>
      <inbound>
        <base />
        <!-- Set the backend service URL dynamically to the Function App's hostname -->
        <set-backend-service base-url="https://${azurerm_function_app.backend_function_app.default_hostname}/api" />
        <!-- Rewrite the URL path to match the Function App's expected path -->
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
# Defines a specific operation (e.g., a GET request to /data) within an API.
resource "azurerm_api_management_api_operation" "get_data_operation" {
  # The name of the parent API Management service.
  api_management_name = azurerm_api_management.apim_service.name
  # The name of the API to which this operation belongs.
  api_name            = azurerm_api_management_api.backend_api.name
  # The resource group containing the API Management service.
  resource_group_name = azurerm_resource_group.main.name
  # A user-friendly display name for the operation.
  display_name        = "Get Data"
  # The HTTP method for this operation (e.g., "GET", "POST").
  method              = "GET"
  # The URL template for this operation (e.g., "/data" will map to /api/data).
  url_template        = "/data" # This will map to /api/data
  # A description of the operation.
  description         = "Retrieves data from the backend."

  # Defines the expected responses for this operation.
  response {
    # The HTTP status code of the response.
    status_code = 200
    # A description of the response.
    description = "Successful response"
  }
}

# 4. Product to manage API access and subscriptions
# Products are used to group APIs and define their visibility and access policies.
resource "azurerm_api_management_product" "starter_product" {
  # A unique identifier for the product.
  product_id          = "starter"
  # The name of the parent API Management service.
  api_management_name = azurerm_api_management.apim_service.name
  # The resource group containing the API Management service.
  resource_group_name = azurerm_resource_group.main.name
  # A user-friendly display name for the product.
  display_name        = "Starter"
  # Indicates whether a subscription is required to access APIs in this product.
  subscription_required = true
  # Indicates whether administrator approval is required for new subscriptions.
  approval_required   = false
  # Indicates whether the product is published (visible to developers).
  published           = true
}

# Link the API to the Product
# Associates a defined API with a product, making it accessible through that product.
resource "azurerm_api_management_product_api" "product_api_link" {
  # The ID of the product.
  product_id          = azurerm_api_management_product.starter_product.product_id
  # The name of the API to link.
  api_name            = azurerm_api_management_api.backend_api.name
  # The name of the parent API Management service.
  api_management_name = azurerm_api_management.apim_service.name
  # The resource group containing the API Management service.
  resource_group_name = azurerm_resource_group.main.name
}

# 5. Subscription (API Key) for the product
# Represents a subscription key that grants access to APIs within a specific product.
resource "azurerm_api_management_subscription" "product_subscription" {
  # The name of the parent API Management service.
  api_management_name = azurerm_api_management.apim_service.name
  # The resource group containing the API Management service.
  resource_group_name = azurerm_resource_group.main.name
  # The ID of the product this subscription is for.
  product_id          = azurerm_api_management_product.starter_product.product_id
  # A user-friendly display name for the subscription.
  display_name        = "StarterSubscription"
  # The ID of the user associated with this subscription (e.g., a built-in admin user).
  user_id             = "576a81577740e21a240656a7" # Built-in 'admin' user ID for API Management
  # The state of the subscription (e.g., "active").
  state = "active"
}