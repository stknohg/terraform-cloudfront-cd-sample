# Terraform sample for CloudFront continuous deployment

TerraformでCloudFrontの継続的デプロイを試すためのサンプルです。

## 前提条件

* Terraform 1.7+
* Terraform AWS Provider 5.12.0+

## ビルド方法

Terraformではプライマリディストリビューションの作成とステージングディストリビューションとのリンクを同時に行えない制限があります。

* 参考 : [Resource: aws_cloudfront_continuous_deployment_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_continuous_deployment_policy#basic-usage)

同時に行おうとすると以下のエラーとなります。

>  Error: creating CloudFront Distribution: InvalidArgument: Continuous deployment policy is not supported during distribution creation.

このため2回に分けて処理を行う必要があります。

### Step.1

最初に`./main.tf`の設定を`link_deployment_policy = false`にしておきます。

```hcl 
# main.tf
module "cloudfront" {
  // snip...
  link_deployment_policy = false
}
```

その上で`terraform init`から`terraform apply`まで行います。

```bash
terraform init
terraform plan
terraform apply
```

これでステージングディストリビューションとのリンク以外のリソースが作成されます。  

### Step.2

次に`./main.tf`の設定を`link_deployment_policy = true`に変更します。

```hcl 
# main.tf
module "cloudfront" {
  // snip...
  link_deployment_policy = true
}
```

もう一度`terraform apply`を実行します。

```bash
terraform plan
terraform apply
```

これでステージングディストリビューションとのリンクが行われすべての作業が完了です。

## アクセス方法

オリジンS3バケットの`/v1/`配下にコンテンツを保存するとプライマリディストリビューションからアクセスできます。  
`/v2/`配下にコンテンツを保存するとステージングディストリビューションからアクセスできます。  

### プライマリ環境

```bash
curl https://<primary>.cloudfront.net/
```

### ステージング環境

`aws-cf-cd-sample`ヘッダを付けてプライマリディストリビューションへアクセスします。

```bash
curl -H 'aws-cf-cd-sample:true' https://<primary>.cloudfront.net/
```

## 削除方法

オリジンS3にコンテンツが残っている場合は事前にすべて削除しておきます。  
そのうえで`terraform destroy`してください。  

```bash
terraform destroy
```

## 制限事項

* CNAMEの設定はしていません
* ログ出力の設定はしていません
* キャッシュ設定はしていません (`CachingDisabled`を使う様にしています)

## ライセンス

* [MIT](/LICENSE)
