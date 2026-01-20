# apimanagement.tf
# このファイルは、API、操作、ポリシー、製品、およびサブスクリプションを含む Azure API Management (APIM) サービスを定義します。
# APIM は、API を管理、保護、公開するためのファサードとして機能します。

# 1. API Management サービス
# メインの Azure API Management サービスインスタンスを定義します。
resource "azurerm_api_management" "apim_service" {
  # API Management サービスの名前。
  name                = var.api_management_service_name
  # APIM サービスがデプロイされる Azure リージョン。
  location            = azurerm_resource_group.main.location
  # API Management サービスを作成するリソースグループ。
  resource_group_name = azurerm_resource_group.main.name
  # API 発行者の名前。
  publisher_name      = "My Company" # 発行者の名前に置き換えてください
  # API 発行者のメールアドレス。
  publisher_email     = "admin@example.com" # メールアドレスに置き換えてください

  # API Management サービスの SKU (価格ティアと容量)。
  # "Developer_1" は開発およびテストに適しています。運用環境には適切な SKU を選択してください。
  sku_name = "Developer_1" # 開発用の基本 SKU。運用環境には適切なものを選択してください。

  # API Management サービスのマネージド ID の構成。
  identity {
    # マネージドサービス ID のタイプ。"SystemAssigned" は Azure が ID を自動的に管理することを意味します。
    type = "SystemAssigned" # API Management のマネージド ID を有効にする
  }
}

# 2. API: バックエンドサービスを表す
# API Management サービス内に API を定義し、バックエンドサービスへのインターフェースとして機能させます。
resource "azurerm_api_management_api" "backend_api" {
  # API Management に表示される API の名前。
  name                = "BackendAPI"
  # API Management サービスを含むリソースグループ。
  resource_group_name = azurerm_resource_group.main.name
  # 親の API Management サービスの名前。
  api_management_name = azurerm_api_management.apim_service.name
  # API のリビジョン番号。
  revision            = "1" # API のリビジョン
  # API のユーザーフレンドリーな表示名。
  display_name        = "Backend API"
  # この API のベース URL パス (例: /api/data へのリクエスト)。
  path                = "api" # この API のベースパス (例: /api/data)
  # クライアントが API にアクセスするために使用できるプロトコル (例: "https")。
  protocols           = ["https"]
  # この API がプロキシするバックエンドサービスの URL (例: Azure Function App のホスト名)。
  service_url         = azurerm_function_app.backend_function_app.default_hostname # Function App のホスト名を指します
  # API の説明。
  description         = "バックエンドの Azure Function と対話するための API。"
}

# バックエンド API の API ポリシー
# URL 書き換えや認証など、API 全体に適用されるポリシーを定義します。
resource "azurerm_api_management_api_policy" "backend_api_policy" {
  # このポリシーが適用される API の名前。
  api_name            = azurerm_api_management_api.backend_api.name
  # 親の API Management サービスの名前。
  api_management_name = azurerm_api_management.apim_service.name
  # API Management サービスを含むリソースグループ。
  resource_group_name = azurerm_resource_group.main.name

  # ポリシーの XML コンテンツ。この例では、Azure Function をターゲットにするように URL を書き換えます。
  xml_content = <<-XML
    <policies>
      <inbound>
        <base />
        <!-- バックエンドサービス URL を Function App のホスト名に動的に設定 -->
        <set-backend-service base-url="https://${azurerm_function_app.backend_function_app.default_hostname}/api" />
        <!-- Function App の予期されるパスに一致するように URL パスを書き換え -->
        <rewrite-uri template="@(context.Request.Url.Path.ToString().Replace("/api", "/"))" />
      </inbound>
      <backend>
        <base />
      </backend>
      <outbound>
        <base />
      </outbound>
      <on-error>
        <base />
      </on-error>
    </policies>
  XML
}

# 3. /data (GET) の API 操作
# API 内の特定の操作 (例: /data への GET リクエスト) を定義します。
resource "azurerm_api_management_api_operation" "get_data_operation" {
  # 親の API Management サービスの名前。
  api_management_name = azurerm_api_management.apim_service.name
  # この操作が属する API の名前。
  api_name            = azurerm_api_management_api.backend_api.name
  # API Management サービスを含むリソースグループ。
  resource_group_name = azurerm_resource_group.main.name
  # 操作のユーザーフレンドリーな表示名。
  display_name        = "Get Data"
  # この操作の HTTP メソッド (例: "GET", "POST")。
  method              = "GET"
  # この操作の URL テンプレート (例: "/data" は /api/data にマッピングされます)。
  url_template        = "/data" # これは /api/data にマッピングされます
  # 操作の説明。
  description         = "バックエンドからデータを取得します。"

  # この操作の予期されるレスポンスを定義します。
  response {
    # レスポンスの HTTP ステータスコード。
    status_code = 200
    # レスポンスの説明。
    description = "Successful response"
  }
}

# 4. API アクセスとサブスクリプションを管理する製品
# 製品は API をグループ化し、その可視性とアクセスポリシーを定義するために使用されます。
resource "azurerm_api_management_product" "starter_product" {
  # 製品の一意の識別子。
  product_id          = "starter"
  # 親の API Management サービスの名前。
  api_management_name = azurerm_api_management.apim_service.name
  # API Management サービスを含むリソースグループ。
  resource_group_name = azurerm_resource_group.main.name
  # 製品のユーザーフレンドリーな表示名。
  display_name        = "Starter"
  # この製品の API にアクセスするためにサブスクリプションが必要かどうかを示します。
  subscription_required = true
  # 新しいサブスクリプションに管理者承認が必要かどうかを示します。
  approval_required   = false
  # 製品が公開されているかどうか (開発者に表示されるかどうか) を示します。
  published           = true
}

# API を製品にリンクする
# 定義された API を製品に関連付け、その製品を通じてアクセスできるようにします。
resource "azurerm_api_management_product_api" "product_api_link" {
  # 製品の ID。
  product_id          = azurerm_api_management_product.starter_product.product_id
  # リンクする API の名前。
  api_name            = azurerm_api_management_api.backend_api.name
  # 親の API Management サービスの名前。
  api_management_name = azurerm_api_management.apim_service.name
  # API Management サービスを含むリソースグループ。
  resource_group_name = azurerm_resource_group.main.name
}

# 5. 製品のサブスクリプション (API キー)
# 特定の製品内の API へのアクセスを許可するサブスクリプションキーを表します。
resource "azurerm_api_management_subscription" "product_subscription" {
  # 親の API Management サービスの名前。
  api_management_name = azurerm_api_management.apim_service.name
  # API Management サービスを含むリソースグループ。
  resource_group_name = azurerm_resource_group.main.name
  # このサブスクリプションの製品の ID。
  product_id          = azurerm_api_management_product.starter_product.product_id
  # サブスクリプションのユーザーフレンドリーな表示名。
  display_name        = "StarterSubscription"
  # このサブスクリプションに関連付けられているユーザーの ID (例: 組み込みの 'admin' ユーザー)。
  user_id             = "576a81577740e21a240656a7" # API Management の組み込みの 'admin' ユーザー ID
  # サブスクリプションの状態 (例: "active")。
  state = "active"
}
