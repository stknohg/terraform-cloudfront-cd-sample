// Provider configuration
terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.12.0"
    }
  }
}

provider "aws" {
}

// Resource configuration
data "aws_caller_identity" "current" {}
module "s3" {
  source = "./modules/s3-origin"
  // Origin S3 bucket name
  bucket_name = "cf-cd-sample-${data.aws_caller_identity.current.account_id}" 
}
module "cloudfront" {
  source = "./modules/cloudfront-cd"
  // OIC name
  oic_name = "cf-cd-sample"
  // Origin configurations
  origin_bucket_id = module.s3.bucket_id
  origin_bucket_arn = module.s3.bucket_arn
  origin_bucket_domain_name = module.s3.bucket_regional_domain_name
  // Header configrations
  staging_header_suffix = "sample"
  staging_header_value = "true"
  // Set whether to link the continuous deployment policy
  // see : https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_continuous_deployment_policy
  link_deployment_policy = false
}
