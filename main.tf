# assumed resources that already exist:
# - a VPC
# - an ssh key in your agent that matches the public key given
locals {
  owner         = var.owner
  vpc           = var.vpc
  my_ip         = var.addr
  ssh_key       = var.ssh_key
  instance_type = "t2.medium"
  user          = "matt"
  internal_cidr = "172.31.101.0/24"
  image_name    = "ubuntu-20"
  names         = ["s0"]
  script        = "k3s"
}

module "access" {
  source        = "./access"
  vpc           = local.vpc
  internal_cidr = local.internal_cidr
  owner         = local.owner
  my_ip         = local.my_ip
  ssh_key       = local.ssh_key
}

module "bastion_server" {
  depends_on = [
    module.access,
  ]
  source            = "./server"
  name              = "bastion"
  instance_type     = local.instance_type
  user              = local.user
  owner             = local.owner
  ssh_key           = local.ssh_key
  image_name        = local.image_name
  ssh_key_name      = module.access.ssh_key_name
  security_group_id = module.access.bastion_security_group_id
  subnet_id         = module.access.subnet_id
  public_access     = true
}

module "bastion_script" {
  depends_on = [
    module.access,
    module.bastion_server,
  ]
  source = "./script"
  addr   = module.bastion_server.public_ip
  user   = local.user
  name   = "bastion"
}

module "initial_server" {
  depends_on = [
    module.bastion_server,
    module.access,
  ]
  source            = "./server"
  name              = local.names[0]
  instance_type     = local.instance_type
  user              = local.user
  owner             = local.owner
  ssh_key           = local.ssh_key
  bastion_address   = module.bastion_server.public_ip
  image_name        = local.image_name
  ssh_key_name      = module.access.ssh_key_name
  security_group_id = module.access.security_group_id
  subnet_id         = module.access.subnet_id
}

module "initial_script" {
  depends_on = [
    module.access,
    module.bastion_server,
    module.initial_server,
  ]
  source          = "./script"
  addr            = module.initial_server.private_ip
  user            = local.user
  name            = local.script
  bastion_address = module.bastion_server.public_ip
}

module "subsequent_servers" {
  depends_on = [
    module.access,
    module.bastion_server,
    module.initial_server,
  ]
  source            = "./server"
  for_each          = toset(slice(local.names,1,length(local.names)))
  name              = each.key
  instance_type     = local.instance_type
  user              = local.user
  owner             = local.owner
  ssh_key           = local.ssh_key
  bastion_address   = module.bastion_server.public_ip
  image_name        = local.image_name
  ssh_key_name      = module.access.ssh_key_name
  security_group_id = module.access.security_group_id
  subnet_id         = module.access.subnet_id
}

module "subsequent_script" {
  depends_on = [
    module.access,
    module.bastion_server,
    module.initial_server,
    module.initial_script,
    module.subsequent_servers,
  ]
  source          = "./script"
  for_each        = module.subsequent_servers
  addr            = each.value.private_ip
  user            = local.user
  initial         = module.initial_server.private_ip
  name            = local.script
  bastion_address = module.bastion_server.public_ip
}
