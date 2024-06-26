output "alb_hostname" {
  value = "${aws_alb.main.dns_name}:${local.app_port}"
}

output "msk_bootstrap" {
  value = module.msk_cluster[0].bootstrap_brokers
}

output "msk_bootstrap_iam" {
  value = module.msk_cluster[0].bootstrap_brokers_sasl_iam
}