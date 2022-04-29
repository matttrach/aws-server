locals {
    images = {
        ubuntu-20 = {
            ami = "ami-09e2adc587f5853ac",
            user = "ubuntu",
            group = "admin",
        },
        windows-2022 = {
            ami = "ami-0e289f424492b5781"
            user = "ec2-user",
            group = "",
        },
        windows-2019 = {
            ami = "ami-05a418fd6eb36fd5b"
            user = "ec2-user",
            group = "",
        },
        rhel-8 = {
            ami = "ami-0371d018e96ee7fee",
            user = "ec2-user",
            group = "wheel",
        },
        rocky-8 = {
            ami = "ami-0382eea882ee397b8",
            user = "ec2-user",
            group = "wheel",
        },
        sles-15 = {
            ami = "ami-09328fe9a122c38b4",
            user = "ec2-user",
            group = "wheel",
        },
    }
}
