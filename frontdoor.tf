# frontdoor.tf

# 1. Azure Front Door Profile (Premium SKU for WAF and advanced features)
resource "azurerm_cdn_frontdoor_profile" "main_profile" {
  name                = var.front_door_name
  resource_group_name = azurerm_resource_group.main.name

  sku_name            = "Premium_AzureFrontDoor"


}

# 2. Front Door Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "main_endpoint" {
  name                     = "${var.front_door_name}-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main_profile.id
  enabled                  = true

}

# 3. WAF Policy for Front Door
resource "azurerm_cdn_frontdoor_firewall_policy" "main_waf_policy" {
  name                = "${var.front_door_name}-waf-policy"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = azurerm_cdn_frontdoor_profile.main_profile.sku_name

  # Managed Rule Set (OWASP)
  managed_rule {
    action = "Block" # Default action for managed rules
    managed_rule_set {
      type    = "OWASP"
      version = "3.2" # Or latest version
    }
  }

  # Policy settings
  policy_setting {
    mode = "Detection" # Or "Prevention"
    custom_block_response {
      status_code = 403
      body        = "Access Denied."
    }
  }

  # Geo-restriction (example for Japan only)
  custom_rule {
    name     = "GeoFilter"
    priority = 100
    action   = "Block"
    enabled  = true
    match_condition {
      match_variable   = "RemoteAddr"
      operator         = "GeoMatch"
      negation_condition = false
      match_values     = ["JP"]
    }
  }
}



# 5. Front Door Origin Groups
resource "azurerm_cdn_frontdoor_origin_group" "static_website_origin_group" {
  name                     = "static-website-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main_profile.id
  session_affinity_enabled = false
  load_balancing {
    sample_size = 4
    successful_samples_required = 3
    additional_latency_in_milliseconds = 50
  }
  health_probe {
    path = "/"
    protocol = "Https"
    request_type = "HEAD"
    interval_in_seconds = 100
  }
}

resource "azurerm_cdn_frontdoor_origin_group" "api_management_origin_group" {
  name                     = "api-management-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main_profile.id
  session_affinity_enabled = false
  load_balancing {
    sample_size = 4
    successful_samples_required = 3
    additional_latency_in_milliseconds = 50
  }
  health_probe {
    path = "/" # Adjust for API health endpoint
    protocol = "Https"
    request_type = "HEAD"
    interval_in_seconds = 100
  }
}

# 6. Front Door Origins
resource "azurerm_cdn_frontdoor_origin" "static_website_origin" {
  name                             = "static-website-origin"
  cdn_frontdoor_origin_group_id    = azurerm_cdn_frontdoor_origin_group.static_website_origin_group.id
  host_name                        = trimprefix(azurerm_storage_account.static_website.primary_web_host, "https://")
  http_port                        = 80
  https_port                       = 443
  origin_host_header               = trimprefix(azurerm_storage_account.static_website.primary_web_host, "https://") # Needs to be the host without scheme
  priority                         = 1
  weight                           = 100
  enabled                          = true
  certificate_name_check_enabled = true
}

resource "azurerm_cdn_frontdoor_origin" "api_management_origin" {
  name                             = "api-management-origin"
  cdn_frontdoor_origin_group_id    = azurerm_cdn_frontdoor_origin_group.api_management_origin_group.id
  host_name                        = trimprefix(azurerm_api_management.apim_service.gateway_regional_url, "https://")
  http_port                        = 80
  https_port                       = 443
  origin_host_header               = trimprefix(azurerm_api_management.apim_service.gateway_regional_url, "https://") # Needs to be the host without scheme
  priority                         = 1
  weight                           = 100
  enabled                          = true
  certificate_name_check_enabled = true
}

# 7. Front Door Route for Static Website (default)
resource "azurerm_cdn_frontdoor_route" "static_website_route" {
  name                        = "static-website-route"
  cdn_frontdoor_endpoint_id   = azurerm_cdn_frontdoor_endpoint.main_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.static_website_origin_group.id
  cdn_frontdoor_profile_id    = azurerm_cdn_frontdoor_profile.main_profile.id
  cdn_frontdoor_origin_ids    = [azurerm_cdn_frontdoor_origin.static_website_origin.id]
  supported_protocols         = ["Http", "Https"]

  patterns_to_match = ["/*"] # Default route for all paths
  forwarding_protocol = "HttpsOnly"
  link_to_default_domain = true
  
  # Cache settings (similar to CloudFront default cache behavior)
  cache {
    query_string_caching_behavior = "UseQueryString"
    query_strings                 = [] # Cache all query strings
  }
}

# 8. Front Door Route for API Management
resource "azurerm_cdn_frontdoor_route" "api_management_route" {
  name                        = "api-management-route"
  cdn_frontdoor_endpoint_id   = azurerm_cdn_frontdoor_endpoint.main_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.api_management_origin_group.id
  cdn_frontdoor_profile_id    = azurerm_cdn_frontdoor_profile.main_profile.id
  cdn_frontdoor_origin_ids    = [azurerm_cdn_frontdoor_origin.api_management_origin.id]
  supported_protocols         = ["Http", "Https"]

  patterns_to_match = ["/api/*"] # Route for API paths
  forwarding_protocol = "HttpsOnly"
  link_to_default_domain = true
  
  # Cache settings (similar to CloudFront cache behavior for API)
  cache {
    query_string_caching_behavior = "BypassCaching" # Don't cache API calls
  }

}
