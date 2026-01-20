# storage.tf

resource "azurerm_storage_account" "static_website" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Locally Redundant Storage; adjust as needed for durability
  min_tls_version          = "TLS1_2"

  static_website {
    index_document     = "index.html"
    error_404_document = "index.html" # A common pattern for single-page applications
  }
}

# Output the primary web endpoint for the static website
output "static_website_endpoint" {
  description = "The primary web endpoint for the static website hosted on Azure Blob Storage."
  value       = azurerm_storage_account.static_website.primary_web_endpoint
}
