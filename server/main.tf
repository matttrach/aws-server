locals {
  instance_type     = var.instance_type
  user              = var.user
  owner             = var.owner
  ssh_key           = var.ssh_key
  ssh_key_name      = var.ssh_key_name
  image_name        = var.image_name
  name              = var.name
  security_group_id = var.security_group_id
  subnet_id         = var.subnet_id
  public            = var.public_access
  bastion           = var.bastion_address
  image             = local.images[local.image_name]
  ami               = local.image.ami
  initial_user      = local.image.user
  admin_group       = local.image.group
}

resource "aws_instance" "server" {
  ami                         = local.ami
  instance_type               = local.instance_type
  vpc_security_group_ids      = [local.security_group_id]
  subnet_id                   = local.subnet_id
  associate_public_ip_address = local.public
  key_name                    = local.ssh_key_name
  instance_initiated_shutdown_behavior = "terminate"
  user_data = <<-EOT
  #cloud-config
  users:
    - default
    - name: ${local.user}
      gecos: ${local.user}
      sudo: ALL=(ALL) NOPASSWD:ALL
      groups: users, ${local.admin_group}
      lock_password: false
      ssh_authorized_keys:
        - ${local.ssh_key}
  EOT

  tags = {
    Name  = local.name
    User  = local.user
    Owner = local.owner
  }

  root_block_device {
    delete_on_termination = true
    volume_size = 100
  }

  connection {
    type         = "ssh"
    user         = local.initial_user
    script_path  = "/home/${local.initial_user}/initial"
    agent        = true
    bastion_host = local.bastion
    host         = local.public ? self.public_ip : self.private_ip
  }

  provisioner "remote-exec" {
    inline = [<<-EOT
      if [ -z $(which cloud-init) ]; then 
        echo "cloud-init not found";
        # check for user, if it doesn't exist generate it
        if [ -z $(awk -F: '{ print $1 }' /etc/passwd | grep ${local.user}) ]; then 
          sudo addgroup ${local.user}
          sudo adduser -g "${local.user}" -s "/bin/sh" -G "${local.user}" -D ${local.user}
          sudo addgroup ${local.user} ${local.admin_group}
          sudo install -d -m 0700 /home/${local.user}/.ssh
          sudo cp .ssh/authorized_keys /home/${local.user}/.ssh
          sudo chown -R ${local.user}:${local.user} /home/${local.user}
          sudo passwd ${local.user} -d '' -u
        fi
        exit 0;
      fi

      max_attempts=15
      attempts=0
      interval=5
      while [ "$(sudo cloud-init status)" != "status: done" ]; do
        echo "cloud init is \"$(sudo cloud-init status)\""
        attempts=$(expr $attempts + 1)
        if [ $attempts = $max_attempts ]; then break; fi
        sleep $interval;
      done
    EOT
    ]
  }
}