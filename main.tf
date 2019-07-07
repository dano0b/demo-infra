terraform {
  backend "gcs" {
    credentials = "account.json"
    bucket      = "terrafrom-state"
    prefix      = "base"
  }
}

provider "google" {
  credentials = "account.json"
  project     = "adam-demo-ekoapp"
  region      = "us-east1"
}
