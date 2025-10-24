# S3 + CloudFront静的サイトホスティング Terraform構成

このレポジトリは、Terraformを使用してS3とCloudFrontで静的ウェブサイトをホスティングするためのインフラストラクチャ構成です。

## 概要

以下のAWSリソースが作成されます：
- S3バケット（静的ウェブサイトホスティング用）
- S3バケットバージョニング
- CloudFront Distribution（CDN）
- CloudFront Origin Access Control（OAC）
- CloudFront Function（URL書き換え用）
- カスタムドメインとACM証明書の設定（オプション）

## 前提条件

- AWS CLI がインストールされていること
- Terraform がインストールされていること（v1.0以上推奨）
- AWS SSOまたはIAMユーザーでの認証が設定済みであること
- （カスタムドメインを使用する場合）ACM証明書が**us-east-1リージョン**で取得済みであること

## セットアップ手順

### 1. レポジトリのクローン

```bash
git clone <repository-url>
cd tf-s3-cloudfront-static-website
```

### 2. AWS認証の設定

AWS SSOを使用する場合：
```bash
export AWS_PROFILE="your profile name"
```

### 3. （オプション）カスタムドメインの設定

カスタムドメインを使用する場合は、`main.tf`の変数を編集するか、`terraform.tfvars`ファイルを作成します：

```hcl
domain_name          = "example.com"
acm_certificate_arn  = "arn:aws:acm:us-east-1:471731794328:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

カスタムドメインを使用しない場合は、これらの変数を空文字列のままにしてください。

### 3. Terraformの初期化

```bash
terraform init
```

### 4. 設定の確認

作成されるリソースを確認します：
```bash
terraform plan
```

### 5. リソースのデプロイ

```bash
terraform apply
```

確認プロンプトで `yes` を入力してデプロイを実行します。

### 6. 静的ファイルのアップロード

S3バケットに静的ファイル（HTML、CSS、JavaScriptなど）をアップロードします：

### 7. ウェブサイトへのアクセス

デプロイ完了後、出力されるCloudFront URLまたはカスタムドメインでウェブサイトにアクセスできます：

- CloudFrontドメイン: `https://xxxxxxxxxxxxx.cloudfront.net`
- カスタムドメイン（設定した場合）: `https://example.com`

### 8. DNSの設定（カスタムドメインを使用する場合）

Route 53またはお使いのDNSプロバイダーで、カスタムドメインをCloudFrontディストリビューションに向けるレコードを作成します：

- **Aレコード（ALIASレコード）**: `example.com` → CloudFrontディストリビューションドメイン
- または **CNAMEレコード**: `example.com` → `xxxxxxxxxxxxx.cloudfront.net`

## カスタマイズ

### バケット名の変更

`main.tf`の変数を編集してS3バケット名をカスタマイズできます：

```hcl
variable "bucket_name" {
  default = "your-custom-bucket-name"
}
```

または、コマンドライン引数で指定：
```bash
terraform apply -var="bucket_name=my-custom-bucket"
```

### CloudFront Functionのカスタマイズ

URL書き換えロジックを変更したい場合は、`main.tf`の`aws_cloudfront_function.url_rewrite`リソースのコード部分を編集してください。

現在の機能：
- `/news/` → `/news/index.html`
- `/about` → `/about/index.html`
- `/style.css` → `/style.css`（拡張子付きファイルはそのまま）

## 構成の詳細

### CloudFront Function

このプロジェクトでは、CloudFront Functionを使用してURLの書き換えを行っています：

```javascript
function handler(event) {
    var request = event.request;
    var uri = request.uri;

    // URIの末尾が'/'の場合、index.htmlを付加する
    if (uri.endsWith('/')) {
        request.uri += 'index.html';
    } 
    // URIにファイル拡張子が含まれず、'/'で終わらない場合、/index.htmlを付加する
    else if (!uri.includes('.')) {
        request.uri += '/index.html';
    }

    return request;
}
```

この関数により、きれいなURLでウェブサイトにアクセスできます。

### セキュリティ

- S3バケットへのアクセスは、CloudFrontのOrigin Access Control（OAC）を通じてのみ許可されています
- CloudFrontは自動的にHTTPSにリダイレクトします（`viewer_protocol_policy = "redirect-to-https"`）
- TLS 1.2以上のプロトコルのみをサポート（カスタムドメイン使用時）

## クリーンアップ

作成したリソースを削除するには：
```bash
terraform destroy
```

## トラブルシューティング

### よくある問題

1. **権限エラー**
   - AWS認証情報が正しく設定されているか確認
   - IAMユーザー/ロールに必要な権限があるか確認（S3、CloudFront、ACMへのアクセス権限が必要）

2. **バケット名の競合**
   - S3バケット名はグローバルに一意である必要があります
   - 既存のバケット名と重複していないか確認し、必要に応じて変数を変更

3. **ACM証明書のリージョンエラー**
   - CloudFrontで使用するACM証明書は**必ずus-east-1リージョン**で作成する必要があります
   - 他のリージョンで作成した証明書は使用できません

4. **CloudFrontの更新に時間がかかる**
   - CloudFrontディストリビューションの作成や更新には15〜30分程度かかることがあります
   - `terraform apply`が完了してもデプロイ中の可能性があるため、しばらく待ってからアクセスしてください

5. **カスタムドメインでアクセスできない**
   - DNS設定が正しく行われているか確認
   - DNSの伝播には最大48時間かかる場合があります
   - ACM証明書がドメインと一致しているか確認

## 出力

デプロイ後、以下の情報が出力されます：
- `cloudfront_domain_name`: CloudFrontディストリビューションのドメイン名
- `s3_website_endpoint`: S3バケットの静的ウェブサイトエンドポイント

## ファイル構成

```
.
├── main.tf          # メインのTerraform構成ファイル
├── backend.tf       # Terraformバックエンド設定
└── README.md        # このファイル
```