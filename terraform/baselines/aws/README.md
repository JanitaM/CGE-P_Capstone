# Lab 5.2 — AWS Security Services Baseline

Terraform baseline that turns on the two account-level detective services CloudTrail and Security Hub, and maps each to the NIST 800-53 controls it satisfies.

## Service-to-control mapping

| Service | File | Control | Enforces |
|---|---|---|---|
| CloudTrail | `cloudtrail.tf` | AU-2 (Audit Events) | `aws_cloudtrail.mgmt` is multi-region with `include_global_service_events = true`, capturing management events across every region and IAM/global services in one trail. |
| CloudTrail | `cloudtrail.tf` | AU-12 (Audit Generation) | The trail is always-on at the account level — logging isn't opt-in per service or per region, so audit records are generated continuously without further action. |
| CloudTrail | `cloudtrail.tf` | AU-10 (Non-repudiation) | `enable_log_file_validation = true` turns on CloudTrail digest files, which let you cryptographically prove a delivered log file hasn't been altered or deleted after the fact. |
| Security Hub | `security_hub.tf` | RA-5 (Vulnerability Scanning) | `aws_securityhub_standards_subscription.fsbp` and `.nist_800_53` continuously evaluate account configuration against AWS Foundational Security Best Practices and NIST 800-53, surfacing misconfigurations as findings. |
| Security Hub | `security_hub.tf` | SI-4 (Information System Monitoring) | `aws_securityhub_account.this` centralizes findings from Security Hub's own checks (and any subscribed product integrations) into one account-wide feed for continuous monitoring. |
| AWS Config | *(not present)* | CM-2, CM-6, CM-8 | Optional in this lab — the account lacks a delivery channel/recorder, so `config.tf` was not created. Config.1 ("AWS Config should be enabled...") appears as a Security Hub finding as a result; see [Known findings](#known-findings). |

## Verification

```bash
TRAIL=$(terraform output -raw trail_name)
aws cloudtrail get-trail-status --name "$TRAIL" --region us-east-1 \
  --profile default --query '{IsLogging:IsLogging,LatestDeliveryTime:LatestDeliveryTime}'
```

Expected: `IsLogging: true`.

```bash
aws securityhub describe-hub --profile default
```

Expected: the hub ARN for this account/region.

Findings evidence is captured with:

```bash
aws securityhub get-findings --max-results 50 --profile default \
  > evidence/lab-5-2/security-hub-findings.json
```

## Known findings

Enabling Security Hub without also enabling AWS Config produces a `Config.1` finding ("AWS Config should be enabled and use the service-linked role for resource recording") — expected in this lab since `config.tf` is not deployed. `evidence/lab-5-2/security-hub-findings.json` captures 15 findings from the FSBP standard, including this one, confirming Security Hub is active and evaluating the account within the 30-minute population window.

## Outputs

- `trail_name` — CloudTrail name for verify commands.
- `trail_bucket` — S3 bucket receiving CloudTrail logs.
- `securityhub_account_id` — Account ID Security Hub is enabled in (also the terraform import id).
