# dns.tf
# このファイルは、Azure DNS ゾーンと DNS レコードを管理し、トラフィックを Azure Front Door インスタンスにルーティングします。
# これには通常、サブドメインおよび場合によってはルートドメイン (apex) 用の CNAME レコードの設定が含まれます。

# 1. Azure DNS ゾーン
# 指定されたドメイン名の Azure DNS 内の DNS ゾーンを定義します。
resource "azurerm_dns_zone" "primary" {
  # この DNS ゾーンが権限を持つドメイン名。
  name                = var.domain_name
  # DNS ゾーンを作成するリソースグループ。
  resource_group_name = azurerm_resource_group.main.name
}

# 2. Azure Front Door を指す 'www' 用 CNAME レコード
# 'www' サブドメイン用の CNAME (Canonical Name) レコードを作成し、Azure Front Door エンドポイントを指します。
resource "azurerm_dns_cname_record" "www" {
  # CNAME レコードの名前 (例: www.example.com の場合は "www")。
  name                = "www"
  # このレコードが作成される DNS ゾーン名。
  zone_name           = azurerm_dns_zone.primary.name
  # DNS ゾーンを含むリソースグループ。
  resource_group_name = azurerm_resource_group.main.name
  # DNS レコードの Time-To-Live (TTL) (秒単位)。
  ttl                 = 300
  # レコードの正規名 (ターゲット)。Azure Front Door エンドポイントのホスト名です。
  record              = azurerm_cdn_frontdoor_endpoint.main_endpoint.host_name
}

# 3. Azure Front Door を指すルートドメイン用 CNAME レコード
# ルートドメイン (apex ドメイン) 用の CNAME レコードを作成し、Azure Front Door を指します。
# 注意: ルートドメインの CNAME (apex レコード) は、DNS 標準で普遍的にサポートされているわけではありません。
# Azure DNS は、このシナリオで "エイリアスレコード" をサポートしています (実質的に CNAME フラットニング)。
# このリソースは、DNS プロバイダーが CNAME フラットニングを許可している場合、ルートドメインの CNAME レコードを作成します。
# そうでない場合、ユーザーは通常、ドメインレジストラレベルでこれを構成するか、
# Front Door のエニーキャスト IP (変更される可能性があります) を指す A レコードを使用する必要があります。
resource "azurerm_dns_cname_record" "root" {
  # "@" はルートドメイン (例: example.com) を表します。
  name                = "@" # ルートドメインを表す
  # このレコードが作成される DNS ゾーン名。
  zone_name           = azurerm_dns_zone.primary.name
  # DNS ゾーンを含むリソースグループ。
  resource_group_name = azurerm_resource_group.main.name
  # DNS レコードの Time-To-Live (TTL) (秒単位)。
  ttl                 = 300
  # レコードの正規名 (ターゲット)。Azure Front Door エンドポイントのホスト名です。
  record              = azurerm_cdn_frontdoor_endpoint.main_endpoint.host_name
}