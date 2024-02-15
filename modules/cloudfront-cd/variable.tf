variable "oic_name" {
  type    = string
}

variable "origin_bucket_id" {
  type    = string
}

variable "origin_bucket_arn" {
  type    = string
}

variable "origin_bucket_domain_name" {
  type    = string
}

variable "staging_header_suffix" {
  type    = string
  description = "Suffix for staring distribution header. Header name will be aws-cf-cd-<staging_header_suffix>."
}

variable "staging_header_value" {
  type    = string
  description = "Header value to access staging distribution."
}

variable "link_deployment_policy" {
  type = bool
  default = false
  description = "Set whether to link the continuous deployment policy."
}