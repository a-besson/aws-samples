# ECR pull through cache of ECR Public: the private subnets have no NAT gateway, so the ECS samples pull public images
# from the private registry (interface endpoints ecr.api and ecr.dkr, layers through the S3 gateway endpoint).
# Repositories are created on the first pull of an image (warm it up from the workstation, see the README), with the
# default AES-256 encryption: they only hold public images.
resource "aws_ecr_pull_through_cache_rule" "ecr_public" {
  ecr_repository_prefix = "ecr-public"
  upstream_registry_url = "public.ecr.aws"
}
