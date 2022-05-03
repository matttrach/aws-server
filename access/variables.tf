variable "vpc" {
  description = "The id of the vpc to provision on."
}

variable "internal_cidr" {
  description = <<-EOT
    The cidr of the subnet you would like to claim in the vpc.
    This cidr must be within the vpc's range.
  EOT
}

variable "owner" {
  description = "The name of the owner to tag resources with, usually your email address."
}

variable "my_ip" {
  description = "The ip of your home computer, used to allow ingress in security group."
}

variable "ssh_key" {
  description = "The contents of the public key to use for ssh access."
}
