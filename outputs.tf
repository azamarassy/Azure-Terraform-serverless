# outputs.tf for Azure

output "resource_group_name" {
  description = "The name of the Azure Resource Group."
  value       = azurerm_resource_group.main.name
}

output "api_management_gateway_url" {
  description = "The URL of the Azure API Management gateway."
  value       = azurerm_api_management.apim_service.gateway_url
}

output "api_management_subscription_primary_key" {
  description = "The primary key for the API Management Starter subscription."
  value       = azurerm_api_management_subscription.product_subscription.primary_key
  sensitive   = true
}

output "function_app_default_hostname" {
  description = "The default hostname of the Azure Function App."
  value       = azurerm_function_app.backend_function_app.default_hostname
}

output "function_app_identity_principal_id" {
  description = "The Principal ID of the System Assigned Managed Identity for the Function App."
  value       = azurerm_function_app.backend_function_app.identity[0].principal_id
}

output "front_door_frontend_endpoint_host_name" {
  description = "The host name of the Azure Front Door frontend endpoint."
  value       = "Placeholder for Azure Front Door Frontend Host Name" # Will be updated later
}

output "static_website_endpoint" {
  description = "The primary web endpoint for the static website hosted on Azure Blob Storage."
  value       = azurerm_storage_account.static_website.primary_web_endpoint
}
