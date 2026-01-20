# permissions.tf
# This file defines Azure Role Assignments to grant necessary permissions
# between different services within the infrastructure. This is crucial
# for secure inter-service communication using Managed Identities.

# 1. Grant API Management Managed Identity access to Function App
# This role assignment allows the Managed Identity of the Azure API Management service
# to invoke (call) the Azure Function App. This is a common pattern for secure
# backend integration without exposing credentials.
resource "azurerm_role_assignment" "apim_to_function_app_invoke" {
  # The scope of the role assignment, specifying which resource the principal has access to.
  # Here, it's scoped to the Function App, meaning APIM can only invoke this specific Function App.
  scope                = azurerm_function_app.backend_function_app.id
  # The name of the built-in role to assign.
  # "Azure Function Data Reader" grants read access to function data and invocation rights.
  # For broader access during development or if more control plane actions are needed, "Contributor" could be used (with caution).
  role_definition_name = "Azure Function Data Reader" # Or "Contributor" for broader access during development
  # The Principal ID of the Managed Identity that is being granted the role.
  # This refers to the System-Assigned Managed Identity of the API Management service.
  principal_id         = azurerm_api_management.apim_service.identity[0].principal_id
}