resource "aws_cloudfront_distribution" "main" {
  enabled      = true
  http_version = "http2"

  # Default root object for web fallback, like a Next.js frontend
  default_root_object = "index.html"

  origin {
    domain_name = aws_lb.alb.dns_name
    origin_id   = "alb-grpc-origin"

    custom_origin_config {
      # Since the ALB is listening on 443 (HTTPS)
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id = "alb-grpc-origin"
    # CloudFront -> viewer must use HTTPS
    viewer_protocol_policy = "redirect-to-https"
    # gRPC typically uses POST for requests, plus HEAD/GET for some reflection
    # gRPC doesn't support AWS WAF request body inspection rules.
    # If you enabled these rules on the web ACL for a distribution, any request that uses gRPC
    # will ignore the request body inspection rules. All other AWS WAF rules will still apply.
    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS",
      "POST"
      # If your gRPC client uses other HTTP verbs, add them here
    ]
    cached_methods = ["GET", "HEAD"] # Typically no caching for gRPC calls

    # A typical AWS managed cache policy for minimal caching
    cache_policy_id = "413b96c6-2d2f-47fd-8d09-406e06b1f4b0"
    # (For reference, there's a "CacheOptimized" default or you can define your own)
  }

  # Attach an ACM certificate in us-east-1
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cloudfront_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  # If you have a custom domain for CloudFront
  aliases = [
    "${var.subdomain}.${var.domain_name}"
  ]
}

resource "aws_route53_record" "app_alias" {
  zone_id = data.aws_route53_zone.main_zone.zone_id
  name    = "${var.subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}
