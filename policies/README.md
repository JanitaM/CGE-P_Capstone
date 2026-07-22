# Compliance Policies

Rego policies enforcing NIST 800-53 controls against `terraform plan -json` output, targeting GCP resources.

| Policy | File | Control | Severity | Enforces |
|---|---|---|---|---|
| SC-28 | `sc28_encryption.rego` | SC-28 (Encryption at Rest) | High | Every `google_storage_bucket` has a populated `encryption { default_kms_key_name }` block. |
| AC-3 | `ac3_no_public.rego` | AC-3 (Access Enforcement) | Critical | Buckets have `uniform_bucket_level_access=true` and `public_access_prevention="enforced"`. Firewalls don't expose ports 22 or 3389 to `0.0.0.0/0`. |
| CM-6 | `cm6_required_tags.rego` | CM-6 (Configuration Settings) | Medium | Every taggable resource (`google_storage_bucket`, `google_compute_instance`, `google_compute_disk`) carries the four required labels: `project`, `environment`, `managed_by`, `compliance_scope`. |

## Remediation

- **SC-28**: Add an `encryption { default_kms_key_name = ... }` block referencing a `google_kms_crypto_key` you control.
- **AC-3**: Set `uniform_bucket_level_access = true` and `public_access_prevention = "enforced"` on buckets. For firewalls, narrow `source_ranges` or remove the rule.
- **CM-6**: Add the four required labels (`project`, `environment`, `managed_by`, `compliance_scope`) to the resource.

## Running tests

```bash
opa test -v policies/
```

## Evaluating against a real plan

```bash
opa eval -d policies -i <path-to-plan.json> data.compliance.sc28.deny --format=pretty
opa eval -d policies -i <path-to-plan.json> data.compliance.ac3.deny  --format=pretty
opa eval -d policies -i <path-to-plan.json> data.compliance.cm6.deny  --format=pretty
```