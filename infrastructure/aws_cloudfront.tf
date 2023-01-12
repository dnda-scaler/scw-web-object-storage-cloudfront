locals {
  cloudfront_ips           = concat(var.cloudfront_regional_ips, var.cloudfront_global_ips)
  object_storage_origin_id = "scw-static-website"
  cloudfront_price_class   = "PriceClass_100"
}

//Cloudfront distribution that is linked with our website configuration
resource "aws_cloudfront_distribution" "object_storage_distribution" {
  origin {
    domain_name = scaleway_object_bucket_website_configuration.web_app_bucket.website_endpoint
    origin_id   = local.object_storage_origin_id
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1", "TLSv1.1"]
      origin_keepalive_timeout = 50
    }
    custom_header {
      name  = "Referer"
      value = local.referer_value
    }
  }
  aliases             = [local.cloudfront_custom_domain]
  price_class         = local.cloudfront_price_class
  enabled             = true
  default_root_object = "index.html"
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.object_storage_origin_id

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cloudfront_certificate.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

//Certificate for Cloudfront Alias
resource "aws_acm_certificate" "cloudfront_certificate" {
  domain_name       = local.cloudfront_custom_domain
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}


output "cloudfront_url_web_app" {
  value = "https://${local.cloudfront_custom_domain}"
}
