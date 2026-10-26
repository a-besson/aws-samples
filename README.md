# AWS Terraform Samples

A collection of **industrial-grade** Terraform samples for various AWS services and architectures. This repository follows a strict separation between **Infrastructure** and **Application** layers.

---

## 🚀 Projects Structure

Every project in this repository follows the same industrial standard:

- **`infra/`**: Terraform stacks, documentation, and infrastructure tests.
- **`app/`**: Application source code, Dockerfiles, and Lambda functions.

---

## 🏗️ Samples Index

### Foundational Stacks
| Sample | Description | Documentation |
| :--- | :--- | :---: |
| [Base](./samples/base) | Unified foundational stack (VPC & AWS Config) | [README](./samples/base/README.md) |

### Service Samples
| Sample | Description | Documentation |
| :--- | :--- | :---: |
| [Aurora PostgreSQL](./samples/rds-aurora-pg) | High-availability Aurora Serverless cluster | [README](./samples/rds-aurora-pg/README.md) |
| [ECS Service](./samples/ecs-service) | Elastic Container Service with Fargate | [README](./samples/ecs-service/README.md) |
| [ECS Task](./samples/ecs-task) | One-off ECS Task definition for batch jobs | [README](./samples/ecs-task/README.md) |
| [MSK with AKHQ](./samples/msk-akhq) | Managed Streaming for Kafka with AKHQ UI | [README](./samples/msk-akhq/README.md) |

---

## 🛠️ Getting Started

### Prerequisites

- `terraform` 1.16.5 (pinned in every stack)
- `awscli` with a valid session (only to deploy; tests need no AWS account)
- `task` (go-task) for orchestration
- `podman` or `docker` for the Floci emulator and KICS
- `pre-commit` for quality checks

### Installation

```bash
# Install the tools (Brewfile), git hooks and TFLint plugins
task setup

# Configure the state bucket, then create it if needed
cp .env.example .env   # set TF_VAR_state_bucket
task bootstrap:s3
```

### Orchestration

```bash
# Initialize a stack, then deploy it (base first, the other samples read its outputs)
task base:init && task base:apply

# Deploy / destroy all stacks
task apply-all
task destroy-all

# Terraform tests of all stacks on the Floci emulator (no AWS account)
task test-all

# Quality gate and security scans (pre-commit, KICS, Trivy)
task review
```

---

## 🛡️ Security & Quality

- **Project Isolation**: Strict `infra/` vs `app/` directory separation.
- **No identifier in code**: the state bucket comes from `.env` (`TF_VAR_state_bucket`), never from the code.
- **Pinned versions**: Terraform, providers and modules are pinned exactly; every variable is validated.
- **Layered Scanning**: Gitleaks, KICS (IaC) and Trivy (config, vulnerabilities, secrets), `fail-on` HIGH/CRITICAL.
- **Offline tests**: `terraform test` applies each stack on [Floci](https://github.com/floci-io/floci) with fake credentials.

## ⚙️ CI

GitHub Actions (`.github/workflows`), on pull requests only, without any cloud credentials:

```text
.github/workflows/
├── _build-sample.yml    # reusable: fmt, init, validate, tflint, then terraform test on Floci
├── build-<sample>.yml   # one per sample (base, ecs-service, ecs-task, msk-akhq, rds-aurora-pg)
├── check-cyber.yml      # KICS and Trivy
└── check-quality.yml    # pre-commit and CodeQL (weekly run included)
```

`.gitlab-ci.yml` mirrors these checks, except `terraform test` on Floci (GitHub only). Renovate (`renovate.json`) keeps
the action digests and the Floci image up to date.
