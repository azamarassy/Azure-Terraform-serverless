# main.tf
# このファイルは、Terraform 構成のエントリポイントとして機能します。
# 必要な Terraform プロバイダーを定義し、Azure プロバイダーを構成し、
# メインのリソースグループと Terraform ステートを保存するためのバックエンドを設定します。

# Terraform 構成ブロック
# 必要な Terraform バージョンとプロバイダーを指定します。
terraform {
  # 必要なプロバイダーとそのバージョンを定義します。
  required_providers {
    # AzureRM プロバイダーを指定します。
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # 互換性のない変更を避けるためにプロバイダーのバージョンを制約します。
    }
  }

  # Azure Storage に Terraform ステートを保存するためのバックエンド構成。
  # このブロックは最初コメントアウトされています。
  # tfstate 用の Azure Storage アカウントとコンテナが作成された後、
  # コメントアウトを解除して構成する必要があります。
  # バックエンド構成は、Terraform が初期化されて式を評価する前に認識されている必要があるため、
  # Terraform 式を使用できません。
  /*
  backend "azurerm" {
    # tfstate ストレージアカウントが配置されているリソースグループの名前。
    resource_group_name  = "your-tfstate-resource-group-name"
    # Terraform ステートを保存するために使用される Azure ストレージアカウントの名前。
    storage_account_name = "yourtfstatestorageaccountname"
    # tfstate ファイルを保存するコンテナの名前。
    container_name       = "tfstate"
    # コンテナ内の tfstate ファイルへのパス。
    key                  = "terraform.tfstate"
  }
  */
}

# Azure プロバイダー構成
# AzureRM プロバイダーをデフォルト設定で構成します。
provider "azurerm" {
  # 'features' ブロックは必須ですが、デフォルト設定の場合は空にできます。
  features {}
}

# メインのリソースグループ
# 他のすべてのリソースがデプロイされるプライマリ Azure リソースグループを定義します。
resource "azurerm_resource_group" "main" {
  # リソースグループの名前。
  name     = var.resource_group_name
  # リソースグループが配置される Azure リージョン。
  location = var.location
}

# Terraform ステートバックエンド用のリソース
# これらのリソースは、Terraform ステートファイルをリモートに保存するための
# Azure ストレージアカウントとコンテナを設定するためのものです。

# ストレージアカウント名がグローバルで一意であることを保証するために、ランダムなサフィックスを生成します。
resource "random_id" "tfstate_suffix" {
  byte_length = 8 # 8 バイトのランダムなバイトを生成し、16 進数で 16 文字になります。
}

# Terraform ステート用ストレージアカウント
resource "azurerm_storage_account" "tfstate" {
  # ランダムなサフィックスで一意化されたストレージアカウントの名前。
  name                     = "tfstate${random_id.tfstate_suffix.hex}" # 一意の名前
  # ストレージアカウントがデプロイされるリソースグループ。
  resource_group_name      = azurerm_resource_group.main.name
  # ストレージアカウントがデプロイされる Azure リージョン。
  location                 = azurerm_resource_group.main.location
  # ストレージアカウントのティア (例: "Standard", "Premium")。
  account_tier             = "Standard"
  # ストレージアカウントのレプリケーションタイプ (例: "LRS", "GRS", "RA-GRS")。
  # GRS (Geo-Redundant Storage) は、データをセカンダリリージョンにレプリケートすることで高い耐久性を提供します。
  account_replication_type = "GRS" # 高い耐久性のための地理冗長ストレージ
  # ストレージアカウントへの接続に必要とされる最小 TLS バージョン。
  min_tls_version          = "TLS1_2"
}

# Terraform ステート用ストレージコンテナ
resource "azurerm_storage_container" "tfstate" {
  # Terraform ステートファイルが保存されるコンテナの名前。
  name                  = "tfstate"
  # このコンテナが作成されるストレージアカウント。
  storage_account_name  = azurerm_storage_account.tfstate.name
  # コンテナのアクセスタイプ (例: "private", "blob", "container")。
  container_access_type = "private"
}
