terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.86.0"
      configuration_aliases = [ aws.acm ]
    }
  }
}

resource "aws_cloudfront_distribution" "cloudfront" {

  origin {
    domain_name = var.origin
    origin_id   = "origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = ""

  default_cache_behavior {
    target_origin_id       = "origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods = ["GET", "HEAD"]

    # Managed policy AllViewer: forward all parameters in viewer requests
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"

    # Managed policy CachingDisabled: policy with caching disabled
    cache_policy_id  = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.cloudfront_cert.arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  aliases = [var.domain.name]
}

resource "aws_acm_certificate" "cloudfront_cert" {

  provider = aws.acm

  domain_name       = var.domain.name
  validation_method = "DNS"
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cloudfront_cert_validation" {

  allow_overwrite = true
  name    = tolist(aws_acm_certificate.cloudfront_cert.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.cloudfront_cert.domain_validation_options)[0].resource_record_type
  zone_id = var.domain.zone_id
  records = [tolist(aws_acm_certificate.cloudfront_cert.domain_validation_options)[0].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cloudfront_cert" {

  provider = aws.acm

  certificate_arn = aws_acm_certificate.cloudfront_cert.arn
  validation_record_fqdns = [ aws_route53_record.cloudfront_cert_validation.fqdn ]
}