# outputs.tf
# このファイルは、Terraform が構成を適用した後に表示される出力値を定義します。
# これらの出力は、デプロイされた Azure リソースに関する重要な情報 (URL、ID、アクセスキーなど) を提供し、
# さらなる構成や統合に役立ちます。

# 出力: リソースグループ名
# この Terraform 構成によって作成されたメインの Azure リソースグループの名前を提供します。
output "resource_group_name" {
  description = "Azure リソースグループの名前。"
  value       = azurerm_resource_group.main.name
}

# 出力: API Management ゲートウェイ URL
# 公開された API にアクセスするために使用される、Azure API Management サービスのゲートウェイ URL を提供します。
output "api_management_gateway_url" {
  description = "Azure API Management ゲートウェイの URL。"
  value       = azurerm_api_management.apim_service.gateway_url
}

# 出力: API Management サブスクリプションのプライマリキー
# API Management の「Starter」製品のプライマリサブスクリプションキーを提供します。
# この値は、ログに平文で表示されないように機密としてマークされています。
output "api_management_subscription_primary_key" {
  description = "API Management Starter サブスクリプションのプライマリキー。"
  value       = azurerm_api_management_subscription.product_subscription.primary_key
  sensitive   = true
}

# 出力: Function App のデフォルトホスト名
# デプロイされた Azure Function App のデフォルトホスト名、つまりその公開 URL を提供します。
output "function_app_default_hostname" {
  description = "Azure Function App のデフォルトホスト名。"
  value       = azurerm_function_app.backend_function_app.default_hostname
}

# 出力: Function App の ID プリンシパル ID
# Function App に関連付けられたシステム割り当てマネージド ID のプリンシパル ID を提供します。
# この ID を使用して、Function App に他の Azure リソースへのアクセス権を付与できます。
output "function_app_identity_principal_id" {
  description = "Function App のシステム割り当てマネージド ID のプリンシパル ID。"
  value       = azurerm_function_app.backend_function_app.identity[0].principal_id
}

# 出力: Front Door フロントエンドエンドポイントのホスト名
# Azure Front Door のフロントエンドエンドポイントのホスト名、つまり公開エントリポイントを提供します。
output "front_door_frontend_endpoint_host_name" {
  description = "Azure Front Door フロントエンドエンドポイントのホスト名。"
  value       = azurerm_cdn_frontdoor_endpoint.main_endpoint.host_name
}

# 出力: 静的ウェブサイトのエンドポイント
# Azure Blob Storage でホストされている静的ウェブサイトのプライマリウェブエンドポイント URL を提供します。
output "static_website_endpoint" {
  description = "Azure Blob Storage でホストされている静的ウェブサイトのプライマリウェブエンドポイント。"
  value       = azurerm_storage_account.static_website.primary_web_endpoint
}

# 出力: DNS ゾーン名
# カスタムドメイン用に作成された Azure DNS ゾーンの名前を提供します。
output "dns_zone_name" {
  description = "Azure DNS ゾーンの名前。"
  value       = azurerm_dns_zone.primary.name
}

# 出力: DNS ゾーンのネームサーバー
# Azure DNS ゾーンのネームサーバーのリストを提供します。
# カスタムドメインが正しく解決されるように、これらのネームサーバーはドメインレジストラで構成する必要があります。
output "dns_zone_nameservers" {
  description = "Azure DNS ゾーンのネームサーバー。"
  value       = azurerm_dns_zone.primary.name_servers
}
