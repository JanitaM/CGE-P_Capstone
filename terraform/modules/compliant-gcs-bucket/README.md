# compliant-gcs-bucket

A Terraform module that provisions a Google Cloud Storage bucket with compliance controls hardcoded into the module body. Consumers cannot disable these controls; they can only set business-level values like environment, retention, and naming.

## What this module creates

- One KMS key ring
- One KMS crypto key (90-day rotation)
- One IAM binding granting the GCS service account encrypt/decrypt rights
- One GCS bucket, encrypted with the above key

## Controls enforced

| Control | Family | How it's enforced |
|---|---|---|
| SC-12 | System and Communications Protection — Cryptographic Key Establishment and Management | The module creates and owns its own KMS key ring and crypto key, rather than relying on Google-managed encryption. See `google_kms_key_ring.ring` and `google_kms_crypto_key.key` in `main.tf`. |
| SC-13 | System and Communications Protection — Cryptographic Protection | The bucket uses a customer-managed encryption key (CMEK) instead of the default Google-managed key. See the `encryption` block in `google_storage_bucket.bucket`. |
| SC-28 | System and Communications Protection — Protection of Information at Rest | Same CMEK encryption as SC-13, applied at rest to all bucket objects by default. |
| AU-11 | Audit and Accountability — Audit Record Retention | Object versioning is enabled, and a retention policy of `var.retention_days` is enforced on every bucket the module creates. See the `versioning` and `retention_policy` blocks. |
| CM-6 | Configuration Management — Configuration Settings | Required labels (`project`, `environment`, `managed_by`, `compliance_scope`) are merged onto every bucket and cannot be removed by a consumer. See `locals.required_labels` in `main.tf`. |

## Inputs

| Name | Description | Default |
|---|---|---|
| `gcp_project` | GCP project ID | none, required |
| `location` | GCS bucket location | `us-central1` |
| `kms_location` | KMS keyring location (single-region only) | `us-central1` |
| `project_label` | Short project identifier | none, required |
| `environment` | `dev`, `staging`, or `prod` | none, required |
| `retention_days` | Retention period in days (`>= 365` if `environment == prod`) | none, required |
| `bucket_name_suffix` | Globally-unique suffix for the bucket name | none, required |
| `labels` | Optional extra labels, merged with required labels | `{}` |

## Outputs

| Name | Description |
|---|---|
| `bucket_url` | `gs://` URL of the created bucket |
| `bucket_self_link` | Self-link of the bucket |
| `kms_key_id` | Resource ID of the CMEK protecting the bucket |
| `compliance_attestation` | Computed map of control status, used as evidence downstream |

## Example usage

\`\`\`hcl
module "data_bucket" {
  source = "../../modules/compliant-gcs-bucket"

  gcp_project        = var.gcp_project
  project_label      = "cgep-lab"
  environment        = "dev"
  retention_days     = 30
  bucket_name_suffix = "dev-data-001"
}
\`\`\`