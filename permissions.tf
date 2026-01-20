# permissions.tf

# 1. Grant API Management Managed Identity access to Function App
# API Management's Managed Identity needs permission to invoke the Function App.
# The 'Azure Function Data Reader' role might be sufficient, or a custom role for 'Microsoft.Web/sites/functions/read' and 'action'.

resource "azurerm_role_assignment" "apim_to_function_app_invoke" {
  scope                = azurerm_function_app.backend_function_app.id
  role_definition_name = "Azure Function Data Reader" # Or "Contributor" for broader access during development
  principal_id         = azurerm_api_management.apim_service.identity[0].principal_id
}
