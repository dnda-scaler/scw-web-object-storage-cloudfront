terraform {
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.9.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = ">= 0.13"
}

provider "scaleway" {
}
provider "aws" {
  region = "us-east-1" //because cloudfront requires this region for its certificate and we are only deployinh it here 
}