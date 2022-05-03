
output "subnet_id" {
  value = aws_subnet.main.id
}

output "bastion_security_group_id" {
    value = aws_security_group.bastion.id
}

output "security_group_id" {
    value = aws_security_group.gap.id
}

output "ssh_key_name" {
    value = aws_key_pair.access.key_name
}
