# variables.tf
# このファイルは、Terraform 構成の入力変数を定義します。
# 変数を使用すると、デプロイをパラメータ化して、異なる環境やプロジェクトで
# より柔軟かつ再利用可能にすることができます。

# 変数: ドメイン名
# アプリケーションのメインドメイン名。これは DNS レコードの設定に使用されます。
variable "domain_name" {
  description = "アプリケーションのメインドメイン名。"
  type        = string
  default     = "example.com" # デフォルト値。Terraform 実行時に上書きできます。
}

# 変数: Azure リージョン
# 大部分のリソースがデプロイされる Azure リージョン。
variable "location" {
  description = "リソースがデプロイされる Azure リージョン。"
  type        = string
  default     = "japaneast" # デフォルトは東日本。変更可能です。
}

# 変数: リソースグループ名
# デプロイされるすべてのリソースを含む Azure リソースグループの名前。
variable "resource_group_name" {
  description = "作成するリソースグループの名前。"
  type        = string
  default     = "rg-serverless-app" # リソースグループのデフォルト名。
}

# 変数: 静的ウェブサイト用ストレージアカウント名
# 静的ウェブサイトのホスティングに使用される Azure ストレージアカウントの名前。
# この名前は Azure 全体でグローバルに一意であり、命名規則 (小文字、特殊文字なし) に従う必要があります。
variable "storage_account_name" {
  description = "静的ウェブサイトホスティング用の Azure ストレージアカウントの名前。"
  type        = string
  default     = "staticwebsiteappstorage" # グローバルで一意、小文字、特殊文字なしである必要があります
}

# 変数: Azure Function App 名
# バックエンドロジックをホストする Azure Function App の名前。
variable "function_app_name" {
  description = "Azure Function App の名前。"
  type        = string
  default     = "func-serverless-app" # Function App のデフォルト名。
}

# 変数: API Management サービス名
# Azure API Management サービスインスタンスの名前。
variable "api_management_service_name" {
  description = "Azure API Management サービスの名前。"
  type        = string
  default     = "apim-serverless-app" # API Management サービスのデフォルト名。
}

# 変数: Front Door プロファイル名
# Azure Front Door プロファイルの名前。
variable "front_door_name" {
  description = "Azure Front Door プロファイルの名前。"
  type        = string
  default     = "afd-serverless-app" # Front Door プロファイルのデフォルト名。
}

# 変数: Azure Function App ログレベル
# Azure Function App のログレベル。
variable "log_level" {
  description = "Azure Function App のログレベル。"
  type        = string
  default     = "INFO" # 一般的なログレベルには "INFO"、"WARNING"、"ERROR"、"DEBUG" があります。
}
