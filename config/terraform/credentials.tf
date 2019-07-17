provider "aws" {
  access_key = "AKIAJODHB2LQUCF5RCZA"
  secret_key = "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"
  region     = "us-east-2"
}

provider "google" {
  credentials = "${file("istiotest-239415-fb9e28e4292c.json")}"
  project     = "istiotest-239415"
  region      = "europe-west1"
}