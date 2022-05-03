
locals {
    vpc           = var.vpc
    internal_cidr = var.internal_cidr
    owner         = var.owner
    my_ip         = var.my_ip
    ssh_key       = var.ssh_key
}

resource "aws_key_pair" "access" {
  key_name   = var.owner
  public_key = local.ssh_key
  tags = {
    "Owner" = local.owner
  }
}

resource "aws_subnet" "main" {
  vpc_id     = local.vpc
  cidr_block = local.internal_cidr
  tags = {
    Owner = local.owner
  }
}

resource "aws_security_group" "bastion" {
  description = "security group for ssh bastion"
  tags = {
    "Owner" = local.owner
  }
}
resource "aws_security_group_rule" "ssh_from_my_ip" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${local.my_ip}/32"]
  security_group_id = resource.aws_security_group.bastion.id
}
resource "aws_security_group_rule" "internal_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [local.internal_cidr]
  security_group_id = resource.aws_security_group.bastion.id
}
resource "aws_security_group_rule" "internal_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [local.internal_cidr]
  security_group_id = resource.aws_security_group.bastion.id
}
resource "aws_security_group_rule" "external_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = resource.aws_security_group.bastion.id
}

resource "aws_security_group" "gap" {
  description = "security group for air gapped installs"
  tags = {
    "Owner" = local.owner
  }
}
resource "aws_security_group_rule" "gap_internal_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [local.internal_cidr]
  security_group_id = resource.aws_security_group.gap.id
}
resource "aws_security_group_rule" "gap_internal_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [local.internal_cidr]
  security_group_id = resource.aws_security_group.gap.id
}
