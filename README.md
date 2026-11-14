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
| [Base](./samples/base) | Unified foundational stack (VPC, endpoints, shared KMS key, ECR cache, AWS Config) | [README](./samples/base/README.md) |

### Service Samples
| Sample | Description | Documentation |
| :--- | :--- | :---: |
| [Aurora PostgreSQL](./samples/rds-aurora-pg) | High-availability Aurora Serverless cluster | [README](./samples/rds-aurora-pg/README.md) |
| [ECS Service](./samples/ecs-service) | Elastic Container Service with Fargate | [README](./samples/ecs-service/README.md) |
| [ECS Task](./samples/ecs-task) | One-off ECS Task definition for batch jobs | [README](./samples/ecs-task/README.md) |
| [MSK with AKHQ](./samples/msk-akhq) | Managed Streaming for Kafka with AKHQ UI | [README](./samples/msk-akhq/README.md) |

### Event-driven Samples
Each one has a trigger, a configured retry, a dead letter destination, and end-to-end tests on the emulator.

| Sample | Description | Documentation |
| :--- | :--- | :---: |
| [Lambda + S3](./samples/lambda-s3) | A file dropped in S3 invokes a Lambda function; asynchronous retries, then an SQS DLQ | [README](./samples/lambda-s3/README.md) |
| [Lambda + Kinesis](./samples/lambda-kinesis) | A Kinesis stream consumed by a Lambda function; partial batch retries, idempotent DynamoDB writes, SQS DLQ | [README](./samples/lambda-kinesis/README.md) |
| [Step Functions + S3](./samples/step-function-s3) | Files dropped in S3 start state machines: a Distributed Map of Lambdas, and an ECS Fargate job, both with retries | [README](./samples/step-function-s3/README.md) |
| [ECS Task + S3](./samples/ecs-task-s3) | A file dropped in S3 runs an ECS task through EventBridge; delivery retry and SQS DLQ | [README](./samples/ecs-task-s3/README.md) |

---

## 🛠️ Getting Started

### Prerequisites

- `terraform` 1.17.2 (pinned in every stack and in CI)
- `awscli` with a valid session (only to deploy; tests need no AWS account)
- `task` (go-task) for orchestration
- `podman` or `docker` for the Floci emulator and KICS
- `python` 3.13, `jq` and the `aws` CLI for the event-driven samples (Python tooling in `.venv`, e2e helpers of the tests)
- `pre-commit` for quality checks

### Installation

```bash
# Install the tools (Brewfile), the Python tooling (.venv), git hooks and TFLint plugins
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

# Python checks of a Lambda sample (ruff, pyright, offline pytest)
task lambda-s3:app-test

# Quality gate and security scans (pre-commit, KICS, Trivy)
task review
```

---

## 🛡️ Security & Quality

- **Project Isolation**: Strict `infra/` vs `app/` directory separation.
- **One encryption key**: a single customer managed KMS key, created in `base`, encrypts every sample.
- **No identifier in code**: the state bucket comes from `.env` (`TF_VAR_state_bucket`), never from the code.
- **Pinned versions**: Terraform, providers and modules are pinned exactly; every variable is validated.
- **Layered Scanning**: Gitleaks, KICS (IaC) and Trivy (config, vulnerabilities, secrets), `fail-on` HIGH/CRITICAL.
- **Offline tests**: `terraform test` applies each stack on [Floci](https://github.com/floci-io/floci) with fake credentials.
- **End-to-end tests on the emulator**: the event-driven samples also drop files, put records and wait for the results
  and for the failure records of their DLQ, inside `terraform test` (`infra/tests/e2e`). The `aws` CLI is only used there,
  through a helper that refuses any endpoint other than the local Floci.

## ⚙️ CI

GitHub Actions (`.github/workflows`), on pull requests only, without any cloud credentials:

```text
.github/workflows/
├── _build-sample.yml    # reusable: fmt, init, validate, tflint, terraform test on Floci, Python checks (ruff, pyright, pytest)
├── build-<sample>.yml   # one per sample (base, ecs-service, ecs-task, msk-akhq, rds-aurora-pg,
│                        #   lambda-s3, lambda-kinesis, step-function-s3, ecs-task-s3)
├── check-cyber.yml      # KICS and Trivy
└── check-quality.yml    # pre-commit and CodeQL (weekly run included)
```

GitHub Actions is the only CI (no GitLab mirror). Renovate (`renovate.json`) is configured to keep the action digests
and the Floci and KICS images (tag and digest, root `Taskfile.yml`) up to date.
