# dns.tf
# This file manages Azure DNS Zone and DNS records to route traffic
# to the Azure Front Door instance. This typically involves setting up
# CNAME records for subdomains and potentially the root domain (apex).

# 1. Azure DNS Zone
# Defines a DNS zone in Azure DNS for a specified domain name.
resource "azurerm_dns_zone" "primary" {
  # The domain name for which this DNS zone is authoritative.
  name                = var.domain_name
  # The resource group in which to create the DNS zone.
  resource_group_name = azurerm_resource_group.main.name
}

# 2. CNAME Record for 'www' pointing to Azure Front Door
# Creates a CNAME (Canonical Name) record for the 'www' subdomain,
# pointing it to the Azure Front Door endpoint.
resource "azurerm_dns_cname_record" "www" {
  # The name of the CNAME record (e.g., "www" for www.example.com).
  name                = "www"
  # The DNS zone name where this record will be created.
  zone_name           = azurerm_dns_zone.primary.name
  # The resource group containing the DNS zone.
  resource_group_name = azurerm_resource_group.main.name
  # The Time-To-Live (TTL) in seconds for the DNS record.
  ttl                 = 300
  # The canonical name (target) of the record, which is the Azure Front Door endpoint hostname.
  record              = azurerm_cdn_frontdoor_endpoint.main_endpoint.host_name
}

# 3. CNAME Record for the root domain pointing to Azure Front Door
# Creates a CNAME record for the root domain (apex domain), pointing it to Azure Front Door.
# Note: Root domain CNAMEs (apex records) are not universally supported by DNS standards.
# Azure DNS supports "Alias records" for this scenario (effectively CNAME flattening).
# This resource will create a CNAME record for the root domain if the DNS provider allows CNAME flattening.
# Otherwise, a user would typically need to configure this at their domain registrar level
# or use A records pointing to Front Door's anycast IPs (which can change).
resource "azurerm_dns_cname_record" "root" {
  # "@" represents the root domain (e.g., example.com).
  name                = "@" # Represents the root domain
  # The DNS zone name where this record will be created.
  zone_name           = azurerm_dns_zone.primary.name
  # The resource group containing the DNS zone.
  resource_group_name = azurerm_resource_group.main.name
  # The Time-To-Live (TTL) in seconds for the DNS record.
  ttl                 = 300
  # The canonical name (target) of the record, which is the Azure Front Door endpoint hostname.
  record              = azurerm_cdn_frontdoor_endpoint.main_endpoint.host_name
}
