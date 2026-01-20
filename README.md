# Terraform を利用した Azure サーバーレスアプリケーション

このリポジトリには、Microsoft Azure にサーバーレスアプリケーションをデプロイするための Terraform 構成が含まれています。アーキテクチャは、グローバルルーティングと WAF 保護のための Azure Front Door、API ゲートウェイ機能のための Azure API Management、バックエンドロジックのための Azure Function App、静的ウェブサイトホスティングのための Azure Blob Storage を活用しています。

## 目次

*   [1. アーキテクチャ概要](#1-アーキテクチャ概要)
*   [2. 使用されている主な Azure サービス](#2-使用されている主な-azure-サービス)
*   [3. 機能](#3-機能)
*   [4. 前提条件](#4-前提条件)
*   [5. デプロイガイド](#5-デプロイガイド)
*   [6. 出力](#6-出力)
*   [7. クリーンアップ](#7-クリーンアップ)
*   [8. 参考資料](#8-参考資料)

## 1. アーキテクチャ概要

デプロイされたアーキテクチャは、サーバーレス API バックエンドを持つ静的ウェブサイトをホストするための、スケーラブルで安全かつ効率的な方法を提供します。

![Azure Architecture Diagram](構成図.jpg)


## 2. 使用されている主な Azure サービス

*   **Azure Front Door Premium:** ウェブアプリケーションのグローバルでスケーラブルなエントリポイントであり、WAF 保護、コンテンツ配信、インテリジェントルーティングを提供します。
*   **Azure API Management:** API の管理、公開、保護、分析を行い、バックエンドサービスのファサードとして機能します。
*   **Azure Function App:** インフラストラクチャを管理することなくイベント駆動型コードを実行するためのサーバーレスコンピューティングサービスです。
*   **Azure Blob Storage (静的ウェブサイトホスティング):** 静的ウェブコンテンツをホストするための費用対効果が高くスケーラブルなストレージです。
*   **Azure DNS:** DNS ドメインをホストし、アプリケーションのカスタムドメインの名前解決を提供します。
*   **Azure リソースグループ:** Azure リソースの論理コンテナです。
*   **Azure ストレージアカウント (Function App および Terraform State 用):** Function App のランタイムと Terraform のステートファイルのための永続的なストレージを提供します。
*   **Azure Application Insights:** Function App を監視するためのアプリケーションパフォーマンス管理 (APM) サービスです。

## 3. 機能

*   **グローバルなトラフィック管理:** Azure Front Door は、ユーザーリクエストを最も近い健全なバックエンドにインテリジェントにルーティングします。
*   **Web アプリケーションファイアウォール (WAF) 保護:** Azure Front Door Premium の統合 WAF は、一般的なウェブの脆弱性や DDoS 攻撃から保護します。
*   **ポリシー適用を備えた API ゲートウェイ:** Azure API Management は、API の集中管理ゲートウェイを提供し、セキュリティ、キャッシュ、レート制限、リクエスト/レスポンス変換を可能にします。
*   **サーバーレスバックエンド:** Azure Function App は、バックエンドロジックを効率的に実行し、需要に応じて自動的にスケーリングします。
*   **静的ウェブサイトホスティング:** Azure Blob Storage を使用したフロントエンドアセットの費用対効果が高く高性能なホスティング。
*   **カスタムドメインサポート:** カスタムドメイン解決のために Azure DNS で構成されています。
*   **Infrastructure as Code (IaC):** 一貫性と再現性のために Terraform を使用して定義およびデプロイされたインフラストラクチャ全体。
*   **マネージドID:** システム割り当てマネージドID を使用して Azure サービス間の安全なアクセスを確立します。

## 4. 前提条件

このインフラストラクチャをデプロイする前に、以下がインストールおよび構成されていることを確認してください。

*   [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) (v1.0.0 以降を推奨)
*   [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (または Azure PowerShell)
*   Azure サブスクリプション
*   Terraform 用に適切に構成された Azure 資格情報 (例: `az login` を実行して)

## 5. デプロイガイド

1.  **リポジトリのクローン:**
    ```bash
    git clone https://github.com/azamarassy/Azure-Terraform-serverless.git
    cd Azure-Terraform-serverless
    ```

2.  **Terraform の初期化:**
    まず、Terraform のステート用のリソースグループとストレージアカウントを手動で作成するか、部分的に適用して作成する必要があります。
    ```bash
    # Azure CLI にログインしていることを確認してください (az login)

    # tfstate ストレージアカウント用のリソースグループが存在しない場合、手動で作成する必要があるかもしれません。
    # az group create --name <tfstate-リソースグループ名> --location <Azure-リージョン>

    # プロバイダープラグインをダウンロードするために terraform init を実行します。
    terraform init
    ```

    **バックエンド構成に関する注意:** `main.tf` には `azurerm` のコメントアウトされたバックエンド構成ブロックが含まれています。`azurerm_storage_account.tfstate` と `azurerm_storage_container.tfstate` リソースが `terraform apply` によって正常に作成されたら、`main.tf` のこのブロックのコメントを外し、プレースホルダーの値をリソースグループ、ストレージアカウント、コンテナの実際の名前で置き換える必要があります。これはリモートステート管理にとって非常に重要です。

3.  **デプロイの計画:**
    ```bash
    terraform plan -out main.tfplan
    ```
    提案された変更を確認します。

4.  **デプロイの適用:**
    ```bash
    terraform apply "main.tfplan"
    ```
    デプロイを確定するためにプロンプトが表示されたら `yes` と入力します。

5.  **カスタムドメインの構成 (オプションですが推奨):**
    カスタムドメインを使用している場合は、ドメインレジストラの NS レコードを Azure DNS が提供するネームサーバー (「出力」セクションを参照) を指すように更新する必要があります。

## 6. 出力

`terraform apply` が成功すると、以下の重要な出力が表示されます。

*   `resource_group_name`: Azure リソースグループの名前。
*   `api_management_gateway_url`: Azure API Management ゲートウェイの URL。
*   `function_app_default_hostname`: Azure Function App のデフォルトホスト名。
*   `front_door_frontend_endpoint_host_name`: Azure Front Door フロントエンドエンドポイントのホスト名。
*   `static_website_endpoint`: 静的ウェブサイトのプライマリウェブエンドポイント。
*   `dns_zone_name`: Azure DNS ゾーンの名前。
*   `dns_zone_nameservers`: Azure DNS ゾーンのネームサーバー (カスタムドメイン構成に重要)。
*   `api_management_subscription_primary_key`: API Management Starter サブスクリプションのプライマリキー (機密情報)。

## 7. クリーンアップ

デプロイされたすべてのリソースを破棄するには:

```bash
terraform destroy
```
破棄を確定するためにプロンプトが表示されたら `yes` と入力します。

## 8. 参考資料

*   [Azure Front Door ドキュメント](https://learn.microsoft.com/ja-jp/azure/frontdoor/)
*   [Azure API Management ドキュメント](https://learn.microsoft.com/ja-jp/azure/api-management/)
*   [Azure Functions ドキュメント](https://learn.microsoft.com/ja-jp/azure/azure-functions/)
*   [Azure Blob Storage (静的ウェブサイト) ドキュメント](https://learn.microsoft.com/ja-jp/azure/storage/blobs/storage-blob-static-website)
*   [Azure DNS ドキュメント](https://learn.microsoft.com/ja-jp/azure/dns/)
*   [Terraform AzureRM プロバイダー ドキュメント](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
