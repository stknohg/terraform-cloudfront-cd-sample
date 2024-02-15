//
// CloudFront with continuous deployment, S3 origin.
//

// Update origin S3 bucket policy
locals {
  // ref : https://developer.hashicorp.com/terraform/language/data-sources#data-resource-dependencies
  aws_cloudfront_distribution_primary_arn = aws_cloudfront_distribution.primary.arn
  aws_cloudfront_distribution_staging_arn = aws_cloudfront_distribution.staging.arn
}
data "aws_iam_policy_document" "cf_origin" {
  policy_id = "PolicyForCloudFrontPrivateContent"
  statement {
    sid = "AllowCloudFrontServicePrincipal"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      "${var.origin_bucket_arn}",
      "${var.origin_bucket_arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [
        local.aws_cloudfront_distribution_primary_arn,
        local.aws_cloudfront_distribution_staging_arn
      ]
    }
  }
}
resource "aws_s3_bucket_policy" "cf_origin" {
  bucket = var.origin_bucket_id
  policy = data.aws_iam_policy_document.cf_origin.json
}

// Origin Access Control (OIC)
resource "aws_cloudfront_origin_access_control" "this" {
  name = var.oic_name
  description = "OIC for continuous deployment environment"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

// Primary CloudFront distribution
resource "aws_cloudfront_distribution" "primary" {
  depends_on = [ 
    aws_cloudfront_origin_access_control.this
  ]
  comment = "Primary distribution"
  staging = false // Primary distribution
  // NOTE: A continuous deployment policy cannot be associated to distribution on creation. Set this argument once the resource exists.
  // see : https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_continuous_deployment_policy
  continuous_deployment_policy_id = var.link_deployment_policy ? aws_cloudfront_continuous_deployment_policy.this.id : null
  enabled = true
  default_root_object = "index.html"
  
  aliases = null
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  origin {
    origin_id = var.origin_bucket_id
    domain_name = var.origin_bucket_domain_name
    origin_path = "/v1" // This origin path changes on each promotion. Must start with "/".
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  default_cache_behavior {
    target_origin_id = var.origin_bucket_id
    compress = true
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods = [ "GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE" ]
    cached_methods = [ "GET", "HEAD" ]
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" // CachingDisabled, No cache
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf" // CORS-S3Origin
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }    
  }
}

// Staging CloudFront distribution
resource "aws_cloudfront_distribution" "staging" {
  depends_on = [
    aws_cloudfront_origin_access_control.this
  ]
  comment = "Staging distribution"
  staging = true // Staging distribution
  enabled = true
  default_root_object = "index.html"
  
  aliases = null // Can't set aliases to the stating distribution 
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  origin {
    origin_id = var.origin_bucket_id
    domain_name = var.origin_bucket_domain_name
    origin_path = "/v2" // This origin path changes on each promotion. Must start with "/".
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  default_cache_behavior {
    target_origin_id = var.origin_bucket_id
    compress = true
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods = [ "GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE" ]
    cached_methods = [ "GET", "HEAD" ]
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" // CachingDisabled, No cache
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf" // CORS-S3Origin
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }    
  }
}

// CloudFront continuous deployment policy
resource "aws_cloudfront_continuous_deployment_policy" "this" {
  enabled = true

  staging_distribution_dns_names {
    items    = [aws_cloudfront_distribution.staging.domain_name]
    quantity = 1
  }

  traffic_config {
    type = "SingleHeader"
    single_header_config {
      header = "aws-cf-cd-${var.staging_header_suffix}" // Must be start "aws-cf-cd-"
      value  = var.staging_header_value
    }
  }
}