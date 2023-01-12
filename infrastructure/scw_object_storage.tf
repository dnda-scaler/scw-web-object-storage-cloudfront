/*
Here we deployed an object storage with the following characteristics 
  - static website setting
  - Bucket Policy that restrict on the referer and Cloudfront IP (so that the bucket is only accessible from Cloudfront location with the secret referer)
  - 
*/
resource "random_string" "referer_value" {
  length           = 16
  special          = false
  override_special = "/@£$"
}
variable "web_bucket_name" {
  type = string
}
locals {
  referer_value = resource.random_string.referer_value.result
  //web_content_location = "../my-web-app/build"
  web_content_location = "../my-web-app/build"
}
resource "scaleway_object_bucket" "web_app_bucket" {
  name = var.web_bucket_name
  tags = {
    purpose = "static-website-cdn-integration"
  }
}

resource "scaleway_object_bucket_website_configuration" "web_app_bucket" {
  bucket = scaleway_object_bucket.web_app_bucket.name
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

resource "scaleway_object_bucket_policy" "web_app_bucket_policy" {
  bucket = scaleway_object_bucket.web_app_bucket.name
  policy = jsonencode(
    {
      "Version" = "2012-10-17",
      "Id"      = "referer-ip-cloudfront-restrict-policy",
      "Statement" = [
        {
          "Sid"       = "GrantToEveryone",
          "Effect"    = "Allow",
          "Principal" = "*",
          "Action" = [
            "s3:GetObject"
          ],
          "Resource" : [
            "${scaleway_object_bucket.web_app_bucket.name}/*"
          ]
          "Condition" : {
            "StringLike" : {
              "aws:Referer" : [local.referer_value]
            },
            "IpAddress" : {
              "aws:SourceIp" : concat(local.cloudfront_ips)
            }
          }
        }
      ]
  })
}


resource "scaleway_object" "web_content" {
  for_each = fileset(local.web_content_location, "**")

  bucket = scaleway_object_bucket.web_app_bucket.name
  key    = each.value

  file = "${local.web_content_location}/${each.value}"
  hash = filemd5("${local.web_content_location}/${each.value}")
}

output "web_bucket_endpoint" {
  value = "https://${scaleway_object_bucket_website_configuration.web_app_bucket.website_endpoint}"
}