# frontdoor.tf
# This file defines the Azure Front Door configuration, including the profile,
# endpoints, Web Application Firewall (WAF) policy, origin groups, origins, and routes.
# Azure Front Door is used as a global, scalable entry-point that uses the Microsoft global edge network
# to create fast, secure, and widely scalable web applications.

# 1. Azure Front Door Profile (Premium SKU for WAF and advanced features)
# The Front Door profile is the top-level resource for managing Front Door.
# The Premium SKU is selected to enable WAF and other advanced features.
resource "azurerm_cdn_frontdoor_profile" "main_profile" {
  # Name of the Front Door profile, typically derived from a variable.
  name                = var.front_door_name
  # The resource group where the Front Door profile will be deployed.
  resource_group_name = azurerm_resource_group.main.name

  # SKU determines the features and pricing tier of the Front Door profile.
  # "Premium_AzureFrontDoor" includes advanced security features like WAF.
  sku_name            = "Premium_AzureFrontDoor"
}

# 2. Front Door Endpoint
# An endpoint is a logical grouping of one or more hostnames that share common routing and security settings.
resource "azurerm_cdn_frontdoor_endpoint" "main_endpoint" {
  # Name of the Front Door endpoint.
  name                     = "${var.front_door_name}-endpoint"
  # Reference to the parent Front Door profile.
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main_profile.id
  # Enables or disables the endpoint. Set to true to make it active.
  enabled                  = true
  # Note: WAF policies are typically linked to routes, not directly to endpoints in the current Front Door Standard/Premium tier.
  # The `cdn_frontdoor_waf_policy_link_id` was removed from here as it's not a valid attribute for the endpoint.
}

# 3. WAF Policy for Front Door
# Defines the Web Application Firewall policy to protect web applications from common attacks.
resource "azurerm_cdn_frontdoor_firewall_policy" "main_waf_policy" {
  # Name of the WAF policy.
  name                = "${var.front_door_name}-waf-policy"
  # The resource group where the WAF policy will be deployed.
  resource_group_name = azurerm_resource_group.main.name
  # SKU of the WAF policy, must match the parent Front Door profile's SKU.
  sku_name            = azurerm_cdn_frontdoor_profile.main_profile.sku_name

  # Managed Rule Set (OWASP)
  # Pre-configured rule sets provided by Azure to protect against common threats.
  managed_rule {
    # Default action to take when a managed rule is triggered (e.g., "Block", "Log", "Redirect").
    action = "Block" # Default action for managed rules
    # Configuration for the specific managed rule set.
    managed_rule_set {
      # Type of the managed rule set, e.g., "OWASP" for Open Web Application Security Project rules.
      type    = "OWASP"
      # Version of the OWASP rule set to use.
      version = "3.2" # Or latest version like "3.1" or "3.0"
    }
  }

  # Policy settings for the WAF.
  policy_setting {
    # Mode of the WAF policy: "Detection" (logs threats) or "Prevention" (blocks threats).
    mode = "Detection" # Or "Prevention"
    # Defines the custom response when a request is blocked by the WAF.
    custom_block_response {
      # HTTP status code to return for blocked requests.
      status_code = 403 # Forbidden
      # Custom message body for blocked requests.
      body        = "Access Denied."
    }
  }

  # Geo-restriction (example for Japan only)
  # Custom rules allow defining specific rules based on various conditions.
  custom_rule {
    # Name of the custom rule.
    name     = "GeoFilter"
    # Priority of the rule. Lower values are evaluated first.
    priority = 100
    # Action to take when the custom rule conditions are met.
    action   = "Block"
    # Enables or disables the custom rule.
    enabled  = true
    # Conditions that must be met for the rule to trigger.
    match_condition {
      # The variable to match against, e.g., "RemoteAddr" for client IP address.
      match_variable   = "RemoteAddr"
      # The operator to use for matching, e.g., "GeoMatch" for geographical matching.
      operator         = "GeoMatch"
      # Whether to negate the condition (e.g., match if NOT in JP).
      negation_condition = false
      # List of values to match against, e.g., "JP" for Japan.
      match_values     = ["JP"]
    }
  }
}

# 5. Front Door Origin Groups
# An origin group is a collection of origins that Front Door can send traffic to.
# It enables load balancing and health probing across multiple origins.
resource "azurerm_cdn_frontdoor_origin_group" "static_website_origin_group" {
  # Name of the origin group.
  name                     = "static-website-origin-group"
  # Reference to the parent Front Door profile.
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main_profile.id
  # Determines if session affinity is enabled for this origin group.
  session_affinity_enabled = false
  # Load balancing settings for distributing traffic among origins.
  load_balancing {
    # Number of samples to consider for health probes.
    sample_size = 4
    # Number of successful samples required to mark an origin as healthy.
    successful_samples_required = 3
    # Additional latency in milliseconds to consider for load balancing decisions.
    additional_latency_in_milliseconds = 50
  }
  # Health probe settings for checking the availability of origins.
  health_probe {
    # Path to use for health probe requests.
    path = "/"
    # Protocol to use for health probes.
    protocol = "Https"
    # Type of HTTP request method for health probes.
    request_type = "HEAD"
    # Interval in seconds between health probe requests.
    interval_in_seconds = 100
  }
}

resource "azurerm_cdn_frontdoor_origin_group" "api_management_origin_group" {
  # Name of the origin group for API Management.
  name                     = "api-management-origin-group"
  # Reference to the parent Front Door profile.
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main_profile.id
  # Determines if session affinity is enabled.
  session_affinity_enabled = false
  # Load balancing settings for API Management origins.
  load_balancing {
    sample_size = 4
    successful_samples_required = 3
    additional_latency_in_milliseconds = 50
  }
  # Health probe settings for API Management origins.
  health_probe {
    # Path to use for API health endpoint (adjust if different).
    path = "/" # Adjust for API health endpoint
    protocol = "Https"
    request_type = "HEAD"
    interval_in_seconds = 100
  }
}

# 6. Front Door Origins
# An origin is the backend content source (e.g., a web app, storage account, or API Management instance).
resource "azurerm_cdn_frontdoor_origin" "static_website_origin" {
  # Name of the static website origin.
  name                             = "static-website-origin"
  # Reference to the origin group this origin belongs to.
  cdn_frontdoor_origin_group_id    = azurerm_cdn_frontdoor_origin_group.static_website_origin_group.id
  # Hostname of the static website, derived from the storage account's primary web host.
  host_name                        = trimprefix(azurerm_storage_account.static_website.primary_web_host, "https://")
  # HTTP port for the origin.
  http_port                        = 80
  # HTTPS port for the origin.
  https_port                       = 443
  # The host header sent to the origin, typically the same as host_name without the scheme.
  origin_host_header               = trimprefix(azurerm_storage_account.static_website.primary_web_host, "https://") # Needs to be the host without scheme
  # Priority of the origin within its origin group.
  priority                         = 1
  # Weight of the origin for load balancing.
  weight                           = 100
  # Enables or disables the origin.
  enabled                          = true
  # Enables or disables certificate name check for HTTPS connections to the origin.
  certificate_name_check_enabled = true
}

resource "azurerm_cdn_frontdoor_origin" "api_management_origin" {
  # Name of the API Management origin.
  name                             = "api-management-origin"
  # Reference to the origin group this origin belongs to.
  cdn_frontdoor_origin_group_id    = azurerm_cdn_frontdoor_origin_group.api_management_origin_group.id
  # Hostname of the API Management gateway.
  host_name                        = trimprefix(azurerm_api_management.apim_service.gateway_regional_url, "https://")
  # HTTP port for the origin.
  http_port                        = 80
  # HTTPS port for the origin.
  https_port                       = 443
  # The host header sent to the API Management origin.
  origin_host_header               = trimprefix(azurerm_api_management.apim_service.gateway_regional_url, "https://") # Needs to be the host without scheme
  # Priority of the origin.
  priority                         = 1
  # Weight of the origin.
  weight                           = 100
  # Enables or disables the origin.
  enabled                          = true
  # Enables or disables certificate name check for HTTPS connections to the origin.
  certificate_name_check_enabled = true
}

# 7. Front Door Route for Static Website (default)
# Defines how requests are routed from Front Door endpoints to origin groups.
resource "azurerm_cdn_frontdoor_route" "static_website_route" {
  # Name of the route.
  name                        = "static-website-route"
  # Reference to the Front Door endpoint this route is associated with.
  cdn_frontdoor_endpoint_id   = azurerm_cdn_frontdoor_endpoint.main_endpoint.id
  # Reference to the origin group this route sends traffic to.
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.static_website_origin_group.id
  # Reference to the parent Front Door profile.
  cdn_frontdoor_profile_id    = azurerm_cdn_frontdoor_profile.main_profile.id
  # List of origin IDs that this route can send traffic to.
  cdn_frontdoor_origin_ids    = [azurerm_cdn_frontdoor_origin.static_website_origin.id]
  # Supported protocols for this route (e.g., "Http", "Https").
  supported_protocols         = ["Http", "Https"]

  # URL patterns that this route matches. "/*" matches all paths.
  patterns_to_match = ["/*"] # Default route for all paths
  # Protocol to use when forwarding requests to the origin.
  forwarding_protocol = "HttpsOnly"
  # Whether to link this route to the default domain of the endpoint.
  link_to_default_domain = true
  
  # Cache settings for this route.
  cache {
    # Behavior for query strings: "UseQueryString" (cache with query strings),
    # "IgnoreQueryString" (ignore query strings for caching), or "BypassCaching".
    query_string_caching_behavior = "UseQueryString"
    # Specific query strings to include/exclude from caching if "UseQueryString" is selected.
    # Empty list means all query strings are considered for caching.
    query_strings                 = [] # Cache all query strings
  }
}

# 8. Front Door Route for API Management
# Defines the routing for API Management traffic through Front Door.
resource "azurerm_cdn_frontdoor_route" "api_management_route" {
  # Name of the API Management route.
  name                        = "api-management-route"
  # Reference to the Front Door endpoint this route is associated with.
  cdn_frontdoor_endpoint_id   = azurerm_cdn_frontdoor_endpoint.main_endpoint.id
  # Reference to the origin group for API Management.
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.api_management_origin_group.id
  # Reference to the parent Front Door profile.
  cdn_frontdoor_profile_id    = azurerm_cdn_frontdoor_profile.main_profile.id
  # List of origin IDs that this route can send traffic to.
  cdn_frontdoor_origin_ids    = [azurerm_cdn_frontdoor_origin.api_management_origin.id]
  # Supported protocols for this route.
  supported_protocols         = ["Http", "Https"]

  # URL patterns for API paths. "/api/*" matches any path under /api.
  patterns_to_match = ["/api/*"] # Route for API paths
  # Protocol to use when forwarding requests to the origin.
  forwarding_protocol = "HttpsOnly"
  # Whether to link this route to the default domain of the endpoint.
  link_to_default_domain = true
  
  # Cache settings for API Management route (typically bypass caching for API calls).
  cache {
    # Bypass caching for API calls.
    query_string_caching_behavior = "BypassCaching" # Don't cache API calls
  }
  # Note: Custom request headers like Ocp-Apim-Subscription-Key are not directly
  # supported on azurerm_cdn_frontdoor_route. They typically require a Rules Engine
  # or other advanced configurations which are outside the scope of this resource.
}