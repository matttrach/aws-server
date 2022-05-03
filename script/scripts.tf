locals {
    scripts = {
        k3s = {
            content = file("${path.module}/scripts/k3s_default.sh"),
        },
        k3s_etcd = {
            content = file("${path.module}/scripts/k3s_etcd.sh"),
        },
        k3s_alpine = {
            content = file("${path.module}/scripts/k3s_alpine.sh"),
        },
        k3s_bin = {
            content = file("${path.module}/scripts/k3s_bin_default.sh"),
        },
        k3s_bin_etcd = {
            content = file("${path.module}/scripts/k3s_bin_etcd.sh"),
        },
        rke2 = {
            content = file("${path.module}/scripts/rke2_default.sh"),
        },
        rke2_bin = {
            content = templatefile("${path.module}/scripts/rke2_bin_default.tftpl",{
                server = var.initial
            }),
        },
        bastion = {
            content = file("${path.module}/scripts/bastion.sh"),
        },
    }
}
