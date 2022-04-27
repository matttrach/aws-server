# assumed resources that already exist:
# - vpc (set as default)
# - subnet in the VPC matching CIDR given https://us-west-1.console.aws.amazon.com/vpc/home?region=us-west-1#subnets
# - vpc security group, allowing only 22 & 8080 to your home IP 'curl ipinfo.io/ip' https://us-west-1.console.aws.amazon.com/ec2/v2/home?region=us-west-1#SecurityGroups:
# - an ssh key added to AWS
# - an ssh key in your agent that matches the public key and the name given
locals {
    instance_type   = "t2.medium"
    use             = "onboarding"
    user            = "matt"
    security_group  = "sg-06bf73fa3affae222"
    vpc             = "vpc-3d1f335a"
    subnet          = "subnet-0835c74adb9e4a860"
    #ami             = "ami-062ef6c2900041916" # alpine x86 with cloud-init
    #initial_user    = "alpine" # this depends on the image!
    #admin_group     = "wheel"
    ami             = "ami-09e2adc587f5853ac" # Ubuntu
    initial_user    = "ubuntu"
    admin_group     = "admin"
    names           = ["s0"]
    servers         = toset(local.names)
    sshkey_name     = "matttrach-initial"
    sshkey          = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGbArPa8DHRkmnIx+2kT/EVmdN1cORPCDYF2XVwYGTsp matt.trachier@suse.com"
    script          = file("${path.module}/install_scripts/rke2_ubuntu_default.sh")
  }

resource "random_uuid" "cluster_token" {
}

resource "aws_instance" "server" {
  for_each                    = local.servers
  ami                         = local.ami
  instance_type               = local.instance_type
  vpc_security_group_ids      = [local.security_group]
  subnet_id                   = local.subnet
  associate_public_ip_address = true
  instance_initiated_shutdown_behavior = "terminate"
  key_name                    = local.sshkey_name
  user_data = <<-EOT
  #cloud-config
  users:
    - default
    - name: ${local.user}
      gecos: ${local.user}
      sudo: ALL=(ALL) NOPASSWD:ALL
      groups: users, admin
      lock_password: false
      ssh_authorized_keys:
        - ${local.sshkey}
  EOT

  tags = {
    Name = each.key
    User = local.user
    Use  = local.use
  }

  root_block_device {
    delete_on_termination = true
    volume_size = 100
  }

  connection {
    type        = "ssh"
    user        = local.initial_user
    script_path = "/home/${local.initial_user}/initial"
    agent       = true
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [<<-EOT
      if [ -z $(which cloud-init) ]; then 
        echo "cloud-init not found";
        # check for user, if it doesn't exist generate it
        if [ -z $(awk -F: '{ print $1}' /etc/passwd | grep ${local.user}) ]; then 
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

resource "null_resource" "script" {
  depends_on = [
    aws_instance.server,
  ]
  for_each = local.servers
  connection {
    type        = "ssh"
    user        = local.user
    script_path = "/home/${local.user}/script"
    agent       = true
    host        = aws_instance.server[each.key].public_ip
  }

  provisioner "file" {
    content = local.script
    destination = "/home/${local.user}/install_script.sh"
  }

  provisioner "remote-exec" {
    inline = [<<-EOT
      sudo mv /home/${local.user}/install_script.sh /root/script.sh
      sudo chmod +x /root/script.sh
    EOT
    ]
  }
}
