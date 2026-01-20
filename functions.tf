# functions.tf
# このファイルは、Azure Function App とそのサポートリソースを定義します。
# これには、ストレージアカウント、監視用の Application Insights、App Service プランが含まれます。
# Azure Function App は、サーバーレスコンピューティング機能を提供します。

# 1. Azure Functions 用ストレージアカウント
# Azure Function App は、トリガーを管理し、関数の実行をログに記録するためにストレージアカウントを必要とします。
resource "azurerm_storage_account" "functions" {
  # ストレージアカウントの名前。グローバルで一意である必要があります。
  name                     = "${var.function_app_name}sa" # 一意の名前が必要
  # ストレージアカウントを作成するリソースグループ。
  resource_group_name      = azurerm_resource_group.main.name
  # ストレージアカウントがデプロイされる Azure リージョン。
  location                 = azurerm_resource_group.main.location
  # ストレージアカウントのティア (例: "Standard", "Premium")。
  account_tier             = "Standard"
  # ストレージアカウントのレプリケーションタイプ (例: "LRS", "GRS", "RA-GRS")。
  account_replication_type = "LRS"
}

# 2. 監視用 Application Insights
# Application Insights は、ライブ Web アプリケーションを監視するためのアプリケーションパフォーマンス管理 (APM) サービスです。
resource "azurerm_application_insights" "app_insights" {
  # Application Insights リソースの名前。
  name                = "${var.function_app_name}-appinsights"
  # Application Insights がデプロイされる Azure リージョン。
  location            = azurerm_resource_group.main.location
  # Application Insights リソースを作成するリソースグループ。
  resource_group_name = azurerm_resource_group.main.name
  # 監視対象のアプリケーションのタイプ (例: "web", "other")。
  application_type    = "web"
}

# 3. Consumption App Service プラン
# Azure Function App のホスティングプランを定義します。
# Consumption プランは自動的にスケーリングし、消費されたコンピューティングリソースに対してのみ課金されます。
resource "azurerm_service_plan" "functions_plan" {
  # App Service プランの名前。
  name                = "${var.function_app_name}-plan"
  # App Service プランがデプロイされる Azure リージョン。
  location            = azurerm_resource_group.main.location
  # App Service プランを作成するリソースグループ。
  resource_group_name = azurerm_resource_group.main.name
  # App Service プランのオペレーティングシステムタイプ (例: "Windows", "Linux")。
  os_type             = "Linux"
  # SKU はプランの価格ティアと機能を決定します。"Y1" は Consumption プラン用です。
  sku_name            = "Y1" # Linux 用 Consumption プラン
}

# 4. Azure Function App
# サーバーレスコードが実行される Azure Function App を定義します。
resource "azurerm_function_app" "backend_function_app" {
  # Function App の名前。
  name                       = var.function_app_name
  # Function App がデプロイされる Azure リージョン。
  location                   = azurerm_resource_group.main.location
  # Function App を作成するリソースグループ。
  resource_group_name        = azurerm_resource_group.main.name
  # Function App が実行される App Service プランの ID。
  app_service_plan_id        = azurerm_service_plan.functions_plan.id
  # 関連付けられたストレージアカウントの名前。
  storage_account_name       = azurerm_storage_account.functions.name
  # 関連付けられたストレージアカウントのアクセスキー。
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key
  # Function App のランタイムバージョン。
  version                    = "~3" # Python ランタイムバージョン (例: Python 3.9) - 正確な文字列は Azure ドキュメントを確認してください

  # Function App のアプリケーション設定。
  app_settings = {
    # 関数のワーカーランタイムを指定します (例: "python", "dotnet")。
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    # 監視用の Application Insights への接続文字列。
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.app_insights.connection_string
    # Consumption プランにとって重要: コードがデプロイパッケージから直接実行されることを保証します。
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false" # Consumption プランにとって重要。コードがパッケージから実行されることを保証する
    # デプロイ中のビルドを有効にします。依存関係に役立ちます。
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true" # パッケージからのビルド用
    # Function App のログレベルを設定します。
    "LOG_LEVEL" = var.log_level
  }

  # Function App のサイト構成設定。
  site_config {
    # Python ランタイムを含む Linux FX バージョンを指定します。
    linux_fx_version = "PYTHON|3.9" # Python 3.9 を指定
  }

  # Function App のマネージド ID の構成。
  identity {
    # マネージドサービス ID のタイプ。"SystemAssigned" は Azure が ID を自動的に管理することを意味します。
    type = "SystemAssigned" # Function App のマネージド ID を有効にする
  }
}