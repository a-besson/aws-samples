# ECS Batch Task Stack

---

## Features

- **ECS Task Definition**: Generic task definition for one-off batch jobs.
- **Fargate Execution**: Serverless execution without managing EC2 instances.
- **IAM Optimized**: Dedicated execution and task roles following least-privilege.
- **CloudWatch Integration**: Focused logging for batch job tracking.

## Quick Start

### 1. Provision
```bash
# Initialize (needs TF_VAR_state_bucket in the root .env) and apply, from the repository root
task ecs-task:init
task ecs-task:apply
```

### 2. Run Task
You can launch the task using the pre-configured `task ecs-task:run` command, which leverages the AWS CLI to execute the task in Fargate.

```bash
# Execute the task on AWS
task ecs-task:run
```

> [!TIP]
> This command will automatically fetch the necessary ARNs and Subnet IDs from the Terraform outputs to launch the task in your VPC.

## Tests

```bash
# terraform test on a throwaway Floci container (fake credentials, no AWS account), from the repository root
task ecs-task:test
```

The test applies the stack on the emulator (`infra/tests/floci.tftest.hcl`); the gaps of the emulator are mocked in the
test file with the reason as a comment. CI runs it on every pull request (`build-ecs-task`).

## Task commands

| Command | Description |
|---|---|
| `task ecs-task:init` | Initialize Terraform with the shared S3 state bucket |
| `task ecs-task:plan` | Plan the changes |
| `task ecs-task:apply` | Apply the changes |
| `task ecs-task:destroy` | Destroy the resources |
| `task ecs-task:test` | `terraform test` on Floci |
| `task ecs-task:docs` | Regenerate the Terraform documentation |

---

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
