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
# Initialize and apply
task apply
```

### 2. Run Task
You can launch the task using the pre-configured `task run` command, which leverages the AWS CLI to execute the task in Fargate.

```bash
# Execute the task on AWS
task run
```

> [!TIP]
> This command will automatically fetch the necessary ARNs and Subnet IDs from the Terraform outputs to launch the task in your VPC.

---

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
