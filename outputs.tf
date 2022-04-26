output "ips" {
  value = { for name in local.names: name => aws_instance.server[name].public_ip }
}
