
locals {
  addr    = var.addr
  user    = var.user
  bastion = var.bastion_address
  script  = local.scripts[var.name]
}

resource "null_resource" "script" {
  connection {
    type         = "ssh"
    user         = local.user
    script_path  = "/home/${local.user}/script"
    agent        = true
    bastion_host = local.bastion
    host         = local.addr
  }

  provisioner "file" {
    content = local.script.content
    destination = "/home/${local.user}/script.sh"
  }

  provisioner "remote-exec" {
    inline = [<<-EOT
      echo 'sudo -i' >> ~/.profile
      sudo mv /home/${local.user}/script.sh /root/script.sh
      sudo chmod +x /root/script.sh
    EOT
    ]
  }
}
