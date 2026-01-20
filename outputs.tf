# outputs.tf for Azure

output "resource_group_name" {
  description = "The name of the Azure Resource Group."
  value       = azurerm_resource_group.main.name
}

output "api_management_gateway_url" {
  description = "The URL of the Azure API Management gateway."
  value       = "Placeholder for Azure API Management Gateway URL" # Will be updated later
}

output "function_app_default_hostname" {
  description = "The default hostname of the Azure Function App."
  value       = "Placeholder for Azure Function App Hostname" # Will be updated later
}

output "front_door_frontend_endpoint_host_name" {
  description = "The host name of the Azure Front Door frontend endpoint."
  value       = "Placeholder for Azure Front Door Frontend Host Name" # Will be updated later
}
