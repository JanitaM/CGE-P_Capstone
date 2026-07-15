terraform {
  required_version = ">= 1.6"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

provider "google" {
  project = var.gcp_project
  region  = "us-central1"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

module "data_bucket" {
  source = "../../modules/compliant-gcs-bucket"

  gcp_project        = var.gcp_project
  project_label      = "cgep-lab"
  environment        = "dev"
  retention_days     = 30
  bucket_name_suffix = "dev-data-${random_id.bucket_suffix.hex}"
}

output "attestation" { value = module.data_bucket.compliance_attestation }
output "bucket_url"  { value = module.data_bucket.bucket_url }