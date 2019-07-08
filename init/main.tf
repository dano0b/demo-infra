provider "aws" {
  version = "~> 2.0"
  region  = "ap-southeast-1"
}

resource "aws_s3_bucket" "terraform-state" {
  bucket = "terraform-state-demo-ekoapp"
  acl    = "private"

  versioning {
    enabled = true
  }
}
