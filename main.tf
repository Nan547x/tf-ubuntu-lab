terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {}

resource "docker_image" "ubuntu" {
  name = "rastasheep/ubuntu-sshd:18.04"
}

resource "docker_network" "tfnet" {
  name = "tfnet"
}

resource "docker_container" "ubuntu_server" {
  count = 5

  name  = "ubuntu-server-${count.index + 1}"
  image = docker_image.ubuntu.name
  must_run = true

  ports {
    internal = 22
    external = 2221 + count.index
  }

  command = ["/usr/sbin/sshd", "-D"]

  mounts {
    target = "/mnt/shared"
    source = "/home/ubuntu/shared"
    type   = "bind"
  }

  networks_advanced {
    name    = docker_network.tfnet.name
    aliases = ["ubuntu-server-${count.index + 1}"]
  }

  connection {
    type     = "ssh"
    user     = "root"
    password = "root"
    host     = "127.0.0.1"
    port     = 2221 + count.index
    timeout  = "30s"
  }

  provisioner "remote-exec" {
  inline = [
    "export DEBIAN_FRONTEND=noninteractive",
    "apt update -y",
    "apt install -y iputils-ping curl vim net-tools"
  ]
}
}
