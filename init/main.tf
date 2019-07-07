provider "google" {
  credentials = "../account.json"
  project     = "adam-demo-ekoapp"
  region      = "us-east1"
}

resource "google_storage_bucket" "terrafrom-state" {
  name     = "terrafrom-state"
  location = "us-east1"
}
