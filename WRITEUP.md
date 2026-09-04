# Lab 4.4 — Evidence Chain of Custody

The `grc-gate` workflow produces a signed, timestamped, retention-locked evidence bundle on every run and stores it in an S3 vault. The table below maps each of the four chain-of-custody properties to the concrete artifact and verification step that proves it.

## Chain of custody, in four properties

| Property | Claim | How it's proven |
|---|---|---|
| Authenticity | The evidence came from this repo's workflow, not a spoofed source. | Each bundle is signed with `cosign sign-blob` using GitHub OIDC keyless signing in the "Bundle + sign + upload to vault" step of `grc-gate.yml`, producing a `.sig.bundle` alongside the tarball. The embedded Fulcio certificate binds the signature to `repo:JanitaM/CGE-P_Capstone`, the `grc-gate.yml` workflow path, and the triggering ref. Checked by `cosign verify-blob --certificate-oidc-issuer 'https://token.actions.githubusercontent.com'` in step 2 of `verify-evidence.sh`. |
| Integrity | The evidence hasn't changed since it was produced. | A `.sha256` sidecar is computed with `shasum -a 256` at bundle time and uploaded alongside the tarball. Step 1 of `verify-evidence.sh` recomputes the hash of the downloaded bundle and compares it against this sidecar. Proved directly in the Lab 4.4 tamper test: appending one byte to a downloaded copy changed the hash (`4b3cc714...` → `edff58f2...`), an immediate mismatch. |
| Timeliness | There's a trustworthy record of when the evidence was produced. | `cosign sign-blob` writes a Rekor transparency log entry (`tlog entry created with index: ...`), embedded in the `.sig.bundle` and checked as part of the bundle verification in step 2 of `verify-evidence.sh`. The log entry is append-only and timestamped independently of the signer, so the signing time can't be backdated after the fact. |
| Preservation | The evidence is still there, protected, when someone comes looking. | The evidence vault has S3 Object Lock enabled in `GOVERNANCE` mode with a default retention period applied to every object on write, defined in `terraform/primitives/evidence-vault/main.tf`. Step 3 of `verify-evidence.sh` checks `get-object-retention` and fails if the window has expired. Proved directly in the Lab 4.4 tamper test: pushing a tampered copy to the same key created a new object version rather than overwriting the original — the original version (`uXRC1JsEN6zjDgpAqTy0nDYnA3w_19PJ`, recorded in `evidence/lab-4-4/receipt.json`) remained locked, unmodified, and still hashes to the value in the receipt. |

## Verification

```bash
EVIDENCE_VAULT=cgep-lab-grc-evidence-vault-72b77bfd bash scripts/verify-evidence.sh 33911871167 --profile <profile>
```

Output: `Verified OK` (cosign) and `CHAIN INTACT for run 33911871167`.

## Supporting run

- Run ID: `33911871167`
- Receipt: `evidence/lab-4-4/receipt.json`
