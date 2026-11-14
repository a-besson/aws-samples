# Test fixture: imports a throwaway self-signed certificate into the emulator's ACM, so the HTTPS listener of the
# stack references a certificate that exists (Floci >= 2.3 rejects a listener certificate the account does not have).
terraform {
  required_version = "1.17.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.100.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.4.2"
    }
  }
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "this" {
  private_key_pem       = tls_private_key.this.private_key_pem
  validity_period_hours = 24
  allowed_uses          = ["key_encipherment", "digital_signature", "server_auth"]

  subject {
    common_name = "akhq.example.com"
  }
}

resource "aws_acm_certificate" "this" {
  private_key      = tls_private_key.this.private_key_pem
  certificate_body = tls_self_signed_cert.this.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}

output "certificate_arn" {
  description = "ARN of the imported certificate"
  value       = aws_acm_certificate.this.arn
}
