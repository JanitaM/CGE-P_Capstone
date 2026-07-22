# Compliance Policies

Rego policies enforcing NIST 800-53 controls against `terraform plan -json` output, covering both GCP (Lab 3.3) and AWS (Lab 3.4) resources.

| Policy | File | Control | Severity | Enforces |
|---|---|---|---|---|
| SC-28 | `sc28_encryption.rego` | SC-28 (Encryption at Rest) | High | Every `google_storage_bucket` has a populated `encryption { default_kms_key_name }` block. |
| SC-28 | `sc28_encryption_aws.rego` | SC-28 (Encryption at Rest) | High | Every `aws_s3_bucket` must have an aws_s3_bucket_server_side_encryption_configuration block. |
| AC-3 | `ac3_no_public.rego` | AC-3 (Access Enforcement) | Critical | Buckets have `uniform_bucket_level_access=true` and `public_access_prevention="enforced"`. Firewalls don't expose ports 22 or 3389 to `0.0.0.0/0`. |
| AC-3 | `ac3_no_public_aws.rego` | AC-3 (Access Enforcement) | Critical | Every aws_s3_bucket must have an aws_s3_bucket_public_access_block referencing it with all four flags true. |
| CM-6 | `cm6_required_tags.rego` | CM-6 (Configuration Settings) | Medium | Every taggable resource (`google_storage_bucket`, `google_compute_instance`, `google_compute_disk`) carries the four required labels: `project`, `environment`, `managed_by`, `compliance_scope`. |
| CM-6 | `cm6_required_tags_aws.rego` | CM-6 (Configuration Settings) | Medium | Every taggable resource (`aws_s3_bucket`, `aws_dynamodb_table`, `aws_lambda_function`, `aws_kms_key`, `aws_cloudtrail`) carries the four required tags: `Project`, `Environment`, `ManagedBy`, `ComplianceScope`. |

## Remediation

**GCP variants:**
- **SC-28**: Add an `encryption { default_kms_key_name = ... }` block referencing a `google_kms_crypto_key` you control.
- **AC-3**: Set `uniform_bucket_level_access = true` and `public_access_prevention = "enforced"` on buckets. For firewalls, narrow `source_ranges` or remove the rule.
- **CM-6**: Add the four required labels (`project`, `environment`, `managed_by`, `compliance_scope`) to the resource.

**AWS variants:**
- **SC-28 (AWS)**: Add an `aws_s3_bucket_server_side_encryption_configuration` block referencing the bucket.
- **AC-3 (AWS)**: Add an `aws_s3_bucket_public_access_block` referencing the bucket, with all four flags set to `true`.
- **CM-6 (AWS)**: Add the four required tags (`Project`, `Environment`, `ManagedBy`, `ComplianceScope`) directly or via provider `default_tags`.

## Running tests

AWS variants aren't covered by `opa test` — the lab validates them by running Conftest against real Terraform plans instead (see below).

```bash
opa test -v policies/
```

## Evaluating against a real plan

For GCP plans:
```bash
opa eval -d policies -i <path-to-plan.json> data.compliance.sc28.deny --format=pretty
opa eval -d policies -i <path-to-plan.json> data.compliance.ac3.deny  --format=pretty
opa eval -d policies -i <path-to-plan.json> data.compliance.cm6.deny  --format=pretty
```

For AWS plans, use the AWS namespaces:
```bash
opa eval -d policies -i <path-to-plan.json> data.compliance.sc28_aws.deny --format=pretty
opa eval -d policies -i <path-to-plan.json> data.compliance.ac3_aws.deny  --format=pretty
opa eval -d policies -i <path-to-plan.json> data.compliance.cm6_aws.deny  --format=pretty
```

In practice, Lab 3.4 runs these through Conftest rather than `opa eval` directly:
```bash
conftest test --policy policies --namespace compliance.sc28_aws <path-to-plan.json>
```
