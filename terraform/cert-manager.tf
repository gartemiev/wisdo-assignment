# CloudFront/ALB certs
resource "aws_acm_certificate" "cloudfront_cert" {
  domain_name       = "*.example.com"
  validation_method = "DNS"
}

# Route53 record for DNS validation
resource "aws_route53_record" "cloudfront_cert_validation" {
  for_each = {
    for domain in aws_acm_certificate.cloudfront_cert.domain_validation_options : domain.domain_name => {
      name   = domain.resource_record_name
      record = domain.resource_record_value
      type   = domain.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main_zone.zone_id
}

# "aws_acm_certificate_validation" finalizes the validation
resource "aws_acm_certificate_validation" "cloudfront_cert_validation" {
  certificate_arn         = aws_acm_certificate.cloudfront_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_cert_validation : record.fqdn]
}
