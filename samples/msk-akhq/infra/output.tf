output "alb_hostname" {
  value       = "https://${aws_alb.main.dns_name}"
  description = "ALB hostname"
}

output "msk_bootstrap" {
  value       = module.msk_cluster[0].bootstrap_brokers
  description = "MSK bootstrap brokers"
}

output "msk_bootstrap_iam" {
  value       = module.msk_cluster[0].bootstrap_brokers_sasl_iam
  description = "MSK bootstrap brokers SASL IAM"
}

output "akhq_admin_password" {
  value       = random_password.akhq_admin.result
  sensitive   = true
  description = "AKHQ admin password (terraform output -raw akhq_admin_password)"
}
