
variable "scw_domain_zone" {
  type        = string
  description = "DNS Zone in scaleway"
}
variable "dns_record_name" {
  type    = string
  default = "my-object-storage-website"
}
locals {
  cloudfront_custom_domain = "${var.dns_record_name}.${var.scw_domain_zone}"
}
resource "scaleway_domain_record" "cloudfront_exposition" {
  dns_zone = var.scw_domain_zone
  name     = var.dns_record_name
  type     = "ALIAS"
  data     = "${aws_cloudfront_distribution.object_storage_distribution.domain_name}."
  ttl      = 3600
}

//Create records that will be used to validate certificate
resource "scaleway_domain_record" "aws_acm_validation_records" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  dns_zone = var.scw_domain_zone
  name     = replace(each.value.name, ".${var.scw_domain_zone}.", "") //We remove the domain from the name to be complaint with scw terrafomr probvider
  type     = each.value.type
  ttl      = 60
  data     = each.value.record
}
