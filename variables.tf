variable "addr" {
  description = <<-EOT
    Your home ip address, this will be added to your security group as the only ingress point.
    You can get/set your address by running 'export TF_VAR_addr=$(curl ipinfo.io/ip)'.
  EOT
}
variable "owner" {
  description = <<-EOT
    The value of the "Owner" tag which will be added to resources, usually this is your email address.
  EOT
}
variable "vpc" {
  description = <<-EOT
    The ID of the vpc you will be using, this must already exist.
  EOT
}
variable "ssh_key" {
  description = "The contents of the public key to use for ssh access."
}
variable "aws_region" {
  description = "The region where your resources should be provisioned."
}
