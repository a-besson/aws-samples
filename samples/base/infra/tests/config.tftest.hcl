run "verify_config_delivery_channel" {
  command = plan

  assert {
    condition     = aws_config_delivery_channel.delivery.name == "delivery-channel"
    error_message = "Config delivery channel name did not match"
  }
}
