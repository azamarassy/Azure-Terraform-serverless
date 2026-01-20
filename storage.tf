# storage.tf
# This file defines the Azure Storage Account used to host a static website.
# Azure Blob Storage can be configured to serve static content directly from a container,
# which is a cost-effective and scalable solution for static web applications.

# Azure Storage Account for Static Website Hosting
resource "azurerm_storage_account" "static_website" {
  # The name of the storage account. Must be globally unique across Azure.
  name                     = var.storage_account_name
  # The resource group in which to create the storage account.
  resource_group_name      = azurerm_resource_group.main.name
  # The Azure region where the storage account will be deployed.
  location                 = azurerm_resource_group.main.location
  # Tier of the storage account (e.g., "Standard", "Premium"). "Standard" is common for static websites.
  account_tier             = "Standard"
  # Replication type for the storage account.
  # LRS (Locally Redundant Storage) provides durability within a single datacenter.
  # Consider GRS (Geo-Redundant Storage) or RA-GRS for higher durability and availability if needed.
  account_replication_type = "LRS" # Locally Redundant Storage; adjust as needed for durability
  # Minimum TLS version required for connections to the storage account. Enforcing TLS 1.2 for security.
  min_tls_version          = "TLS1_2"

  # Configuration for static website hosting.
  static_website {
    # The default document to serve when a request is made to the root or a directory.
    index_document     = "index.html"
    # The document to serve when a 404 Not Found error occurs.
    # For Single Page Applications (SPAs), this often points to the index.html
    # to allow client-side routing to handle the URL.
    error_404_document = "index.html" # A common pattern for single-page applications
  }
}