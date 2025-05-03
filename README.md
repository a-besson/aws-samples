# AWS Samples


## Getting started

```bash
# First setup VPC & VPCE required by all other modules
terraform -chdir=./vpc init; terraform -chdir=./vpc apply --auto-approve;

# Then provision your module
terraform -chdir=./aurora-pg init; terraform -chdir=./aurora-pg apply --auto-approve;
```

Quality checks:

```bash
pre-commit run -a
```



### [Amazon MSK with AKHQ UI](./msk-akhq/README.md)