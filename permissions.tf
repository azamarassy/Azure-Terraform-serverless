# permissions.tf
# このファイルは、インフラストラクチャ内の異なるサービス間で必要なアクセス許可を付与するための Azure ロール割り当てを定義します。
# これは、マネージド ID を使用した安全なサービス間通信にとって非常に重要です。

# 1. API Management マネージド ID に Function App へのアクセスを許可する
# このロール割り当ては、Azure API Management サービスのマネージド ID が
# Azure Function App を呼び出す (実行する) ことを許可します。これは、資格情報を公開せずに安全な
# バックエンド統合を行うための一般的なパターンです。
resource "azurerm_role_assignment" "apim_to_function_app_invoke" {
  # ロール割り当てのスコープ。プリンシパルがアクセスできるリソースを指定します。
  # ここでは Function App にスコープが設定されており、APIM はこの特定の Function App のみを呼び出すことができます。
  scope                = azurerm_function_app.backend_function_app.id
  # 割り当てる組み込みロールの名前。
  # "Azure Function Data Reader" は、関数データへの読み取りアクセスと呼び出し権限を付与します。
  # 開発中により広範なアクセスが必要な場合や、より多くのコントロールプレーンアクションが必要な場合は、"Contributor" を使用することもできます (注意して)。
  role_definition_name = "Azure Function Data Reader" # または開発中に広範なアクセスが必要な場合は "Contributor"
  # ロールを付与されるマネージド ID のプリンシパル ID。
  # これは API Management サービスのシステム割り当てマネージド ID を指します。
  principal_id         = azurerm_api_management.apim_service.identity[0].principal_id
}
