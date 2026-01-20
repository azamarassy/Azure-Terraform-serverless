# outputs.tf
# This file defines the output values that will be displayed after Terraform applies the configuration.
# These outputs provide important information about the deployed Azure resources,
# such as URLs, IDs, and access keys, which can be useful for further configuration or integration.

# Output: Resource Group Name
# Provides the name of the main Azure Resource Group created by this Terraform configuration.
output "resource_group_name" {
  description = "The name of the Azure Resource Group."
  value       = azurerm_resource_group.main.name
}

# Output: API Management Gateway URL
# Provides the URL of the Azure API Management service's gateway, used to access published APIs.
output "api_management_gateway_url" {
  description = "The URL of the Azure API Management gateway."
  value       = azurerm_api_management.apim_service.gateway_url
}

# Output: API Management Subscription Primary Key
# Provides the primary subscription key for the "Starter" product in API Management.
# This value is marked as sensitive to prevent it from being displayed in plaintext in logs.
output "api_management_subscription_primary_key" {
  description = "The primary key for the API Management Starter subscription."
  value       = azurerm_api_management_subscription.product_subscription.primary_key
  sensitive   = true
}

# Output: Function App Default Hostname
# Provides the default hostname of the deployed Azure Function App, which is its public URL.
output "function_app_default_hostname" {
  description = "The default hostname of the Azure Function App."
  value       = azurerm_function_app.backend_function_app.default_hostname
}

# Output: Function App Identity Principal ID
# Provides the Principal ID of the System-Assigned Managed Identity associated with the Function App.
# This ID can be used to grant the Function App access to other Azure resources.
output "function_app_identity_principal_id" {
  description = "The Principal ID of the System Assigned Managed Identity for the Function App."
  value       = azurerm_function_app.backend_function_app.identity[0].principal_id
}

# Output: Front Door Frontend Endpoint Hostname
# Provides the hostname of the Azure Front Door's frontend endpoint, which is the public entry point.
output "front_door_frontend_endpoint_host_name" {
  description = "The host name of the Azure Front Door frontend endpoint."
  value       = azurerm_cdn_frontdoor_endpoint.main_endpoint.host_name
}

# Output: Static Website Endpoint
# Provides the primary web endpoint URL for the static website hosted on Azure Blob Storage.
output "static_website_endpoint" {
  description = "The primary web endpoint for the static website hosted on Azure Blob Storage."
  value       = azurerm_storage_account.static_website.primary_web_endpoint
}

# Output: DNS Zone Name
# Provides the name of the Azure DNS Zone created for the custom domain.
output "dns_zone_name" {
  description = "The name of the Azure DNS Zone."
  value       = azurerm_dns_zone.primary.name
}

# Output: DNS Zone Nameservers
# Provides the list of nameservers for the Azure DNS Zone.
# These nameservers must be configured at the domain registrar for the custom domain to resolve correctly.
output "dns_zone_nameservers" {
  description = "The nameservers for the Azure DNS Zone."
  value       = azurerm_dns_zone.primary.name_servers
}