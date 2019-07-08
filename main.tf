terraform {
  backend "s3" {
    bucket = "terraform-state-demo-ekoapp"
    key    = "terraform-state"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  version = "~> 2.0"
  region  = "ap-southeast-1"
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "terraform-state-demo-ekoapp"
    key    = "terraform-state"
    region = "ap-southeast-1"
  }
}
