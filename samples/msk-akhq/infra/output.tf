output "alb_hostname" {
  value       = "${aws_alb.main.dns_name}:${local.app_port}"
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
