
variable "aws_region" {
  type        = string
  default     = "eu-west-3"
  description = "AWS target region"
}

variable "aws_profile" {
  type        = string
  default     = "default"
  description = "AWS profile"
}

variable "terraform_states_bucket" {
  type        = string
  default     = "aws-lab-tf-states"
  description = "Terraform states bucket"
}