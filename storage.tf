# storage.tf
# このファイルは、静的ウェブサイトをホストするために使用される Azure Storage Account を定義します。
# Azure Blob Storage は、コンテナから直接静的コンテンツを配信するように構成でき、
# 静的ウェブアプリケーションにとって費用対効果が高くスケーラブルなソリューションです。

# 静的ウェブサイトホスティング用の Azure Storage Account
resource "azurerm_storage_account" "static_website" {
  # ストレージアカウントの名前。Azure 全体でグローバルに一意である必要があります。
  name                     = var.storage_account_name
  # ストレージアカウントを作成するリソースグループ。
  resource_group_name      = azurerm_resource_group.main.name
  # ストレージアカウントがデプロイされる Azure リージョン。
  location                 = azurerm_resource_group.main.location
  # ストレージアカウントのティア (例: "Standard", "Premium")。「Standard」は静的ウェブサイトで一般的です。
  account_tier             = "Standard"
  # ストレージアカウントのレプリケーションタイプ。
  # LRS (ローカル冗長ストレージ) は、単一のデータセンター内での耐久性を提供します。
  # 必要に応じて、より高い耐久性と可用性のために GRS (地理冗長ストレージ) または RA-GRS を検討してください。
  account_replication_type = "LRS" # ローカル冗長ストレージ。耐久性に応じて調整してください。
  # ストレージアカウントへの接続に必要とされる最小 TLS バージョン。セキュリティのために TLS 1.2 を強制します。
  min_tls_version          = "TLS1_2"

  # 静的ウェブサイトホスティングの構成。
  static_website {
    # ルートまたはディレクトリへのリクエスト時に配信されるデフォルトのドキュメント。
    index_document     = "index.html"
    # 404 Not Found エラーが発生したときに配信されるドキュメント。
    # シングルページアプリケーション (SPA) の場合、これは多くの場合 index.html を指し、
    # クライアントサイドルーティングが URL を処理できるようにします。
    error_404_document = "index.html" # シングルページアプリケーションの一般的なパターン
  }
}
