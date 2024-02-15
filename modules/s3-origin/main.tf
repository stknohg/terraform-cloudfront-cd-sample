//
// S3 bucket for CloudFront origin
//

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
}
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// Sample index.html
resource "aws_s3_object" "v1_index_html" {
  bucket = aws_s3_bucket.this.id
  key    = "/v1/index.html"
  source = "${path.module}/v1-index.html"
  content_type = "text/html"
}
resource "aws_s3_object" "v2_index_html" {
  bucket = aws_s3_bucket.this.id
  key    = "/v2/index.html"
  source = "${path.module}/v2-index.html"
  content_type = "text/html"
}
