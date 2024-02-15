output "primary_distribution_id" {
  value = aws_cloudfront_distribution.primary.id
}

output "primary_distribution_arn" {
  value = aws_cloudfront_distribution.primary.arn
}

output "staging_distribution_id" {
  value = aws_cloudfront_distribution.staging.id
}

output "staging_distribution_arn" {
  value = aws_cloudfront_distribution.staging.arn
}

output "continuous_deployment_policy_id" {
  value = aws_cloudfront_continuous_deployment_policy.this.id
}
