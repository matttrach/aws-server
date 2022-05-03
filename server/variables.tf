
variable "instance_type" {
  description = "The name designation of the aws instance type to use."
}
variable "user" {
  description = "The user to install on the server."
}
variable "owner" {
  description = "The owner to tag resources with."
}
variable "ssh_key" {
  description = "The contents of the public key to add to the server for ssh access."
}
variable "ssh_key_name" {
  description = "The name of the ssh keypair which is already in AWS for initial access."
}
variable "image_name" {
  description = "The designation from images.tf of the ami to use."
}
variable "name" {
  description = "The name to give the server."
}
variable "security_group_id" {
  description = "The id of the security group which already exists in aws to apply to the server."
}
variable "subnet_id" {
  description = "The id of the subnet which already exists in aws to provision the server on."
}
variable "public_access" {
  description = "Whether or not the server should get a public ip address."
  default = false
}
variable "bastion_address" {
  description = "The IP address of the bastion host if applicable."
  default     = ""
}
