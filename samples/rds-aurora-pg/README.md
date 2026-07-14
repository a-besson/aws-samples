# Aurora PostgreSQL Stack

---

## Features

- **Aurora Serverless v2**: Automatic scaling based on application demand.
- **High Availability**: Multi-AZ deployment within the VPC database subnets.
- **Security**: Data encrypted at rest, IAM database authentication enabled.
- **Integration**: Pre-configured security groups for VPC-native access.

## Quick Start

```bash
# Initialize and apply
task apply

# Destroy
task destroy
```

---

See [infra/TFDOCS.md](./infra/TFDOCS.md) for the full list of requirements, providers, modules, resources, inputs and outputs.

## IAM Auth Lambda Sample (`app/lambdas/sample-rds-iam-auth`)

This sample ships a Lambda handler demonstrating IAM database authentication against the
Aurora cluster (`app/lambdas/sample-rds-iam-auth`), but it is **not currently wired into
Terraform** (`infra/lambda.tf` keeps the module call commented out). Deploying it requires
IAM role, security group and networking decisions beyond a mechanical fix - see the
"Blocages" section of the latest MCO run report before enabling it.
