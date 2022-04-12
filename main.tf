# assumed resources that already exist:
# - vpc (set as default)
# - subnet in the VPC matching CIDR given https://us-west-1.console.aws.amazon.com/vpc/home?region=us-west-1#subnets
# - key pair https://us-west-1.console.aws.amazon.com/ec2/v2/home?region=us-west-1#KeyPairs
# - vpc security group, allowing only 22 & 8080 to your home IP 'curl ipinfo.io/ip' https://us-west-1.console.aws.amazon.com/ec2/v2/home?region=us-west-1#SecurityGroups:
# - ubuntu image from cannonical 
locals {
    instance_type = "t2.medium"
    key_name = "matttrach-initial"
    name = "mt-k3s-default"
    user = "matttrach"
    use = "onboarding"
    security_group = "sg-06bf73fa3affae222"
    vpc = "vpc-3d1f335a"
    subnet = "subnet-0835c74adb9e4a860"
    ami = "ami-01f87c43e618bf8f0"
    servers = toset(["k3s-etcd-k0","k3s-etcd-k1","k3s-etcd-k2","k3s-etcd-e0"])
    agents = toset(["k3s-etcd-k1","k3s-etcd-k2"])
}

data "aws_vpc" "selected" {
  default = true
}

resource "random_uuid" "cluster_token" {
}

resource "aws_instance" "k3s" {
  for_each               = local.servers
  ami                    = local.ami
  instance_type          = local.instance_type
  vpc_security_group_ids = [local.security_group]
  subnet_id              = local.subnet
  key_name               = local.key_name
  instance_initiated_shutdown_behavior = "terminate"
  associate_public_ip_address = true
  user_data = <<-EOT
  #cloud-config
  disable_root: false
  EOT

  tags = {
    Name = each.key
    User = local.user
    Use  = local.use
  }

  connection {
    type        = "ssh"
    user        = "root"
    script_path = "/usr/local/bin/initial"
    agent       = true
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [<<-EOT
      max_attempts=15
      interval=5
      attempts=0
      while [ "$(cloud-init status)" != "status: done" ]; do
        echo "cloud init is \"$(cloud-init status)\""
        attempts=$(expr $attempts + 1)
        if [ $attempts = $max_attempts ]; then break; fi
        sleep $interval;
      done
    EOT
    ]
  }
}

resource "null_resource" "start_etcd" {
  depends_on = [
    aws_instance.k3s,
  ]

  connection {
    type        = "ssh"
    user        = "root"
    script_path = "/usr/local/bin/start_etcd"
    agent       = true
    host        = aws_instance.k3s["k3s-etcd-e0"].public_ip
  }

  provisioner "remote-exec" {
    inline = [<<-EOT
      apt update
      ETCD_VER=v3.4.18

      if [ -z $(which etcd) ]; then
        rm -f /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz
        rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test

        GOOGLE_URL=https://storage.googleapis.com/etcd
        curl -L $GOOGLE_URL/$ETCD_VER/etcd-$ETCD_VER-linux-amd64.tar.gz -o /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz
        tar xzvf /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1
        rm -f /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz

        mv /tmp/etcd-download-test/etcd /usr/bin/etcd
        mv /tmp/etcd-download-test/etcdctl /usr/bin/etcdctl
      fi

      etcd --version
      etcdctl version

      etcd & 
      sleep 5
      etcdctl --endpoints="http://$HOST:2379" put foo "HelloWorld"
      etcdctl --endpoints="http://$HOST:2379" get foo
    EOT
    ]
  }
}

resource "null_resource" "start_server" {
  depends_on = [
    aws_instance.k3s,
    null_resource.start_etcd,
  ]

  connection {
    type        = "ssh"
    user        = "root"
    script_path = "/usr/local/bin/start_server"
    agent       = true
    host        = aws_instance.k3s["k3s-etcd-k0"].public_ip
  }

  provisioner "remote-exec" {
    inline = [<<-EOT
      apt update
      ETCD_IP=${aws_instance.k3s["k3s-etcd-e0"].public_ip}
      curl \
        -sfL https://get.k3s.io | \
        K3S_TOKEN=${random_uuid.cluster_token.result} \
        K3S_DATASTORE_ENDPOINT="http://$ETCD_IP:2379" \
        sh -
    EOT
    ]
  }
}

resource "null_resource" "start_agents" {
  depends_on = [
    aws_instance.k3s,
    null_resource.start_etcd,
    null_resource.start_server,
  ]
  for_each = local.agents
  connection {
    type        = "ssh"
    user        = "root"
    script_path = "/usr/local/bin/start_agents"
    agent       = true
    host        = aws_instance.k3s["k3s-etcd-k0"].public_ip
  }

  provisioner "remote-exec" {
    inline = [<<-EOT
      apt update
      ETCD_IP=${aws_instance.k3s["k3s-etcd-e0"].public_ip}
      curl \
        -sfL https://get.k3s.io | \
        K3S_TOKEN=${random_uuid.cluster_token.result} \
        K3S_DATASTORE_ENDPOINT="http://$ETCD_IP:2379" \
        K3S_URL="${aws_instance.k3s["k3s-etcd-k0"].public_ip}" \
        INSTALL_K3S_SKIP_START=1 \
        sh -
      sleep 10
    EOT
    ]
  }
}

resource "null_resource" "validate_status" {
  depends_on = [
    aws_instance.k3s,
    null_resource.start_etcd,
    null_resource.start_server,
    null_resource.start_agents,
  ]

  connection {
    type        = "ssh"
    user        = "root"
    script_path = "/usr/local/bin/validate_status"
    agent       = true
    host        = aws_instance.k3s["k3s-etcd-k0"].public_ip
  }

  provisioner "remote-exec" {
    inline = [<<-EOT
      kubectl get nodes
    EOT
    ]
  }
}
