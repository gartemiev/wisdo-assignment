data "aws_caller_identity" "current" {}

# Route53 record for app.example.com CloudFront
data "aws_route53_zone" "main_zone" {
  name         = var.domain_name
  private_zone = false
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

