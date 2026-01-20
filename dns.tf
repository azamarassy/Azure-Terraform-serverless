# dns.tf

# 1. Azure DNS Zone
resource "azurerm_dns_zone" "primary" {
  name                = var.domain_name
  resource_group_name = azurerm_resource_group.main.name
}

# 2. CNAME Record for 'www' pointing to Azure Front Door
resource "azurerm_dns_cname_record" "www" {
  name                = "www"
  zone_name           = azurerm_dns_zone.primary.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 300
  record              = azurerm_cdn_frontdoor_endpoint.main_endpoint.host_name
}

# 3. CNAME Record for the root domain pointing to Azure Front Door
# Note: Root domain CNAMEs (apex records) are not universally supported by DNS standards.
# Azure DNS supports "Alias records" for this scenario (effectively CNAME flattening).
# This resource will create a CNAME record for the root domain if the DNS provider allows CNAME flattening.
# Otherwise, a user would typically need to configure this at their domain registrar level
# or use A records pointing to Front Door's anycast IPs (which can change).
resource "azurerm_dns_cname_record" "root" {
  name                = "@" # Represents the root domain
  zone_name           = azurerm_dns_zone.primary.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 300
  record              = azurerm_cdn_frontdoor_endpoint.main_endpoint.host_name
}