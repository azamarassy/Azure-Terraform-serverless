# frontdoor.tf
# このファイルは、プロファイル、エンドポイント、Web アプリケーションファイアウォール (WAF) ポリシー、
# オリジングループ、オリジン、およびルートを含む Azure Front Door の構成を定義します。
# Azure Front Door は、Microsoft のグローバルエッジネットワークを使用して、高速で安全かつ
# 広範囲にスケーラブルな Web アプリケーションを作成するためのグローバルでスケーラブルなエントリポイントとして使用されます。

# 1. Azure Front Door プロファイル (WAF および高度な機能向け Premium SKU)
# Front Door プロファイルは、Front Door を管理するための最上位リソースです。
# WAF およびその他の高度な機能を有効にするために Premium SKU が選択されています。
resource "azurerm_cdn_frontdoor_profile" "main_profile" {
  # Front Door プロファイルの名前。通常は変数から派生します。
  name                = var.front_door_name
  # Front Door プロファイルがデプロイされるリソースグループ。
  resource_group_name = azurerm_resource_group.main.name

  # SKU は Front Door プロファイルの機能と価格ティアを決定します。
  # "Premium_AzureFrontDoor" には、WAF のような高度なセキュリティ機能が含まれています。
  sku_name            = "Premium_AzureFrontDoor"
}

# 2. Front Door エンドポイント
# エンドポイントは、共通のルーティングおよびセキュリティ設定を共有する 1 つ以上のホスト名の論理的なグループ化です。
resource "azurerm_cdn_frontdoor_endpoint" "main_endpoint" {
  # Front Door エンドポイントの名前。
  name                     = "${var.front_door_name}-endpoint"
  # 親の Front Door プロファイルへの参照。
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main_profile.id
  # エンドポイントを有効または無効にします。アクティブにするには true に設定します。
  enabled                  = true
  # 注意: WAF ポリシーは、現在の Front Door Standard/Premium ティアでは、エンドポイントに直接ではなく、通常ルートにリンクされます。
  # `cdn_frontdoor_waf_policy_link_id` はエンドポイントの有効な属性ではないため、ここから削除されました。
}

# 3. Front Door 用 WAF ポリシー
# 一般的な攻撃から Web アプリケーションを保護するための Web アプリケーションファイアウォールポリシーを定義します。
resource "azurerm_cdn_frontdoor_firewall_policy" "main_waf_policy" {
  # WAF ポリシーの名前。
  name                = "${var.front_door_name}-waf-policy"
  # WAF ポリシーがデプロイされるリソースグループ。
  resource_group_name = azurerm_resource_group.main.name
  # WAF ポリシーの SKU。親の Front Door プロファイルの SKU と一致する必要があります。
  sku_name            = azurerm_cdn_frontdoor_profile.main_profile.sku_name

  # マネージドルールセット (OWASP)
  # 一般的な脅威から保護するために Azure が提供する事前構成済みのルールセット。
  managed_rule {
    # マネージドルールがトリガーされたときに実行するデフォルトのアクション (例: "Block", "Log", "Redirect")。
    action = "Block" # マネージドルールのデフォルトアクション
    # 特定のマネージドルールセットの構成。
    managed_rule_set {
      # マネージドルールセットのタイプ。例: OWASP ルールについては "OWASP"。
      type    = "OWASP"
      # 使用する OWASP ルールセットのバージョン。
      version = "3.2" # または "3.1" や "3.0" のような最新バージョン
    }
  }

  # WAF のポリシー設定。
  policy_setting {
    # WAF ポリシーのモード: "Detection" (脅威をログに記録) または "Prevention" (脅威をブロック)。
    mode = "Detection" # または "Prevention"
    # WAF によってリクエストがブロックされたときのカスタムレスポンスを定義します。
    custom_block_response {
      # ブロックされたリクエストに対して返される HTTP ステータスコード。
      status_code = 403 # Forbidden
      # ブロックされたリクエストのカスタムメッセージ本文。
      body        = "Access Denied."
    }
  }

  # 地域制限 (日本のみの例)
  # カスタムルールを使用すると、さまざまな条件に基づいて特定のルールを定義できます。
  custom_rule {
    # カスタムルールの名前。
    name     = "GeoFilter"
    # ルールの優先度。低い値が最初に評価されます。
    priority = 100
    # カスタムルールの条件が満たされたときに実行するアクション。
    action   = "Block"
    # カスタムルールを有効または無効にします。
    enabled  = true
    # ルールがトリガーされるために満たす必要がある条件。
    match_condition {
      # 照合する変数。例: クライアント IP アドレスの場合は "RemoteAddr"。
      match_variable   = "RemoteAddr"
      # 照合に使用する演算子。例: 地域の一致の場合は "GeoMatch"。
      operator         = "GeoMatch"
      # 条件を否定するかどうか (例: 日本にいない場合に一致)。
      negation_condition = false
      # 照合する値のリスト。例: 日本の場合は "JP"。
      match_values     = ["JP"]
    }
  }
}

# 5. Front Door オリジングループ
# オリジングループは、Front Door がトラフィックを送信できるオリジンのコレクションです。
# 複数のオリジン間でロードバランシングとヘルスプローブを可能にします。
resource "azurerm_cdn_frontdoor_origin_group" "static_website_origin_group" {
  # オリジングループの名前。
  name                     = "static-website-origin-group"
  # 親の Front Door プロファイルへの参照。
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main_profile.id
  # このオリジングループでセッションアフィニティが有効になっているかどうかを決定します。
  session_affinity_enabled = false
  # オリジン間でトラフィックを分散するためのロードバランシング設定。
  load_balancing {
    # ヘルスプローブのために考慮するサンプルの数。
    sample_size = 4
    # オリジンを正常とマークするために必要な成功サンプルの数。
    successful_samples_required = 3
    # ロードバランシングの決定のために考慮する追加のレイテンシ (ミリ秒単位)。
    additional_latency_in_milliseconds = 50
  }
  # オリジンの可用性を確認するためのヘルスプローブ設定。
  health_probe {
    # ヘルスプローブリクエストに使用するパス。
    path = "/"
    # ヘルスプローブに使用するプロトコル。
    protocol = "Https"
    # ヘルスプローブの HTTP リクエストメソッドのタイプ。
    request_type = "HEAD"
    # ヘルスプローブリクエスト間の間隔 (秒単位)。
    interval_in_seconds = 100
  }
}

resource "azurerm_cdn_frontdoor_origin_group" "api_management_origin_group" {
  # API Management 用オリジングループの名前。
  name                     = "api-management-origin-group"
  # 親の Front Door プロファイルへの参照。
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main_profile.id
  # セッションアフィニティが有効になっているかどうかを決定します。
  session_affinity_enabled = false
  # API Management オリジン用のロードバランシング設定。
  load_balancing {
    sample_size = 4
    successful_samples_required = 3
    additional_latency_in_milliseconds = 50
  }
  # API Management オリジン用のヘルスプローブ設定。
  health_probe {
    # API ヘルスエンドポイントに使用するパス (異なる場合は調整)。
    path = "/" # API ヘルスエンドポイントに合わせて調整
    protocol = "Https"
    request_type = "HEAD"
    interval_in_seconds = 100
  }
}

# 6. Front Door オリジン
# オリジンはバックエンドのコンテンツソースです (例: Web アプリ、ストレージアカウント、または API Management インスタンス)。
resource "azurerm_cdn_frontdoor_origin" "static_website_origin" {
  # 静的ウェブサイトオリジンの名前。
  name                             = "static-website-origin"
  # このオリジンが属するオリジングループへの参照。
  cdn_frontdoor_origin_group_id    = azurerm_cdn_frontdoor_origin_group.static_website_origin_group.id
  # 静的ウェブサイトのホスト名。ストレージアカウントのプライマリ Web ホストから派生します。
  host_name                        = trimprefix(azurerm_storage_account.static_website.primary_web_host, "https://")
  # オリジンの HTTP ポート。
  http_port                        = 80
  # オリジンの HTTPS ポート。
  https_port                       = 443
  # オリジンに送信されるホストヘッダー。通常はスキームなしの host_name と同じです。
  origin_host_header               = trimprefix(azurerm_storage_account.static_website.primary_web_host, "https://") # スキームなしのホスト名が必要
  # オリジングループ内でのオリジンの優先度。
  priority                         = 1
  # ロードバランシングのためのオリジンの重み。
  weight                           = 100
  # オリジンを有効または無効にします。
  enabled                          = true
  # オリジンへの HTTPS 接続の証明書名チェックを有効または無効にします。
  certificate_name_check_enabled = true
}

resource "azurerm_cdn_frontdoor_origin" "api_management_origin" {
  # API Management オリジンの名前。
  name                             = "api-management-origin"
  # このオリジンが属するオリジングループへの参照。
  cdn_frontdoor_origin_group_id    = azurerm_cdn_frontdoor_origin_group.api_management_origin_group.id
  # API Management ゲートウェイのホスト名。
  host_name                        = trimprefix(azurerm_api_management.apim_service.gateway_regional_url, "https://")
  # オリジンの HTTP ポート。
  http_port                        = 80
  # オリジンの HTTPS ポート。
  https_port                       = 443
  # API Management オリジンに送信されるホストヘッダー。
  origin_host_header               = trimprefix(azurerm_api_management.apim_service.gateway_regional_url, "https://") # スキームなしのホスト名が必要
  # オリジンの優先度。
  priority                         = 1
  # オリジンの重み。
  weight                           = 100
  # オリジンを有効または無効にします。
  enabled                          = true
  # オリジンへの HTTPS 接続の証明書名チェックを有効または無効にします。
  certificate_name_check_enabled = true
}

# 7. 静的ウェブサイト用 Front Door ルート (デフォルト)
# Front Door エンドポイントからオリジングループへのリクエストのルーティング方法を定義します。
resource "azurerm_cdn_frontdoor_route" "static_website_route" {
  # ルートの名前。
  name                        = "static-website-route"
  # このルートが関連付けられている Front Door エンドポイントへの参照。
  cdn_frontdoor_endpoint_id   = azurerm_cdn_frontdoor_endpoint.main_endpoint.id
  # このルートがトラフィックを送信するオリジングループへの参照。
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.static_website_origin_group.id
  # 親の Front Door プロファイルへの参照。
  cdn_frontdoor_profile_id    = azurerm_cdn_frontdoor_profile.main_profile.id
  # このルートがトラフィックを送信できるオリジン ID のリスト。
  cdn_frontdoor_origin_ids    = [azurerm_cdn_frontdoor_origin.static_website_origin.id]
  # このルートでサポートされているプロトコル (例: "Http", "Https")。
  supported_protocols         = ["Http", "Https"]

  # このルートが一致する URL パターン。"/*" はすべてのパスに一致します。
  patterns_to_match = ["/*"] # すべてのパスのデフォルトルート
  # オリジンにリクエストを転送するときに使用するプロトコル。
  forwarding_protocol = "HttpsOnly"
  # このルートをエンドポイントのデフォルトドメインにリンクするかどうか。
  link_to_default_domain = true
  
  # このルートのキャッシュ設定。
  cache {
    # クエリ文字列の動作: "UseQueryString" (クエリ文字列を含むキャッシュ)、
    # "IgnoreQueryString" (キャッシュのためにクエリ文字列を無視)、または "BypassCaching"。
    query_string_caching_behavior = "UseQueryString"
    # "UseQueryString" が選択されている場合に、キャッシュに含める/除外する特定のクエリ文字列。
    # 空のリストは、すべてのクエリ文字列がキャッシュのために考慮されることを意味します。
    query_strings                 = [] # すべてのクエリ文字列をキャッシュ
  }
}

# 8. API Management 用 Front Door ルート
# Front Door を介した API Management トラフィックのルーティングを定義します。
resource "azurerm_cdn_frontdoor_route" "api_management_route" {
  # API Management ルートの名前。
  name                        = "api-management-route"
  # このルートが関連付けられている Front Door エンドポイントへの参照。
  cdn_frontdoor_endpoint_id   = azurerm_cdn_frontdoor_endpoint.main_endpoint.id
  # API Management 用のオリジングループへの参照。
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.api_management_origin_group.id
  # 親の Front Door プロファイルへの参照。
  cdn_frontdoor_profile_id    = azurerm_cdn_frontdoor_profile.main_profile.id
  # このルートがトラフィックを送信できるオリジン ID のリスト。
  cdn_frontdoor_origin_ids    = [azurerm_cdn_frontdoor_origin.api_management_origin.id]
  # このルートでサポートされているプロトコル。
  supported_protocols         = ["Http", "Https"]

  # API パスの URL パターン。"/api/*" は /api 以下のすべてのパスに一致します。
  patterns_to_match = ["/api/*"] # API パスのルート
  # オリジンにリクエストを転送するときに使用するプロトコル。
  forwarding_protocol = "HttpsOnly"
  # このルートをエンドポイントのデフォルトドメインにリンクするかどうか。
  link_to_default_domain = true
  
  # API Management ルートのキャッシュ設定 (通常、API コールはキャッシュをバイパスします)。
  cache {
    # API コールのキャッシュをバイパスします。
    query_string_caching_behavior = "BypassCaching" # API コールをキャッシュしない
  }
  # 注意: Ocp-Apim-Subscription-Key のようなカスタムリクエストヘッダーは、
  # azurerm_cdn_frontdoor_route で直接サポートされていません。通常、これには
  # このリソースの範囲外であるルールエンジンまたはその他の高度な構成が必要です。
}