# Base Infrastructure Stack

---

## Features

### Networking (VPC)
- **Multi-AZ VPC**: High-availability networking across 3 Availability Zones.
- **Subnet Segmentation**: Dedicated public, private, and database subnets.
- **VPC Endpoints**: Secure, private access to AWS services.

### Governance (AWS Config)
- **Configuration Recorder**: Records all configuration changes.
- **Continuous Monitoring**: Real-time tracking of resource changes.
- **Dedicated S3 Storage**: Secure export of configuration snapshots.

## Quick Start

```bash
# Initialize (needs TF_VAR_state_bucket in the root .env) and apply, from the repository root
task base:init
task base:apply

# Destroy
task base:destroy
```

## Tests

```bash
# terraform test on a throwaway Floci container (fake credentials, no AWS account), from the repository root
task base:test
```

The test applies the stack on the emulator (`infra/tests/floci.tftest.hcl`); the gaps of the emulator are mocked in the
test file with the reason as a comment. CI runs it on every pull request (`build-base`).

## Task commands

| Command | Description |
|---|---|
| `task base:init` | Initialize Terraform with the shared S3 state bucket |
| `task base:plan` | Plan the changes |
| `task base:apply` | Apply the changes |
| `task base:destroy` | Destroy the resources |
| `task base:test` | `terraform test` on Floci |
| `task base:docs` | Regenerate the Terraform documentation |

---

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
