variable "addr" {
  description = "the address of the server to copy the script to"
}
variable "bastion_address" {
  description = "the address of the bastion server to pass through to copy the script to"
  default     = ""
}
variable "user" {
  description = "the user to login as, will copy to root"
}
variable "name" {
  description = "the name of the script to run, see scripts.tf for choices"
}
variable "initial" {
  description = "the ip of the cluster server to join if joining a cluster"
  default     = ""
}
