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
# Initialize and apply
task apply

# Destroy
task destroy
```

---

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
