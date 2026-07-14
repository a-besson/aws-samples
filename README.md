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

- `terraform` >= 1.9.0
- `awscli` configured with valid credentials
- `task` (go-task) for orchestration
- `pre-commit` for quality checks

### Installation

```bash
# Initialize dependency, skills and state bucket
task init
```

### Orchestration

```bash
# Deploy all stacks
task apply-all

# Destroy all stacks
task destroy-all

# Run quality and security scans
task review
```

---

## 🛡️ Security & Quality

Every sample includes:
- **Project Isolation**: Strict `infra/` vs `app/` directory separation.
- **State Automation**: Automated S3 bucket provisioning for state management.
- **Layered Scanning**: Integrated Gitleaks, KICS (IaC), and Trivy (Security).
- **Automated Testing**: Built-in `terraform test` validation.
