packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.3.0"
    }
  }
}

variable "region"  { default = "ap-southeast-1" }
variable "git_sha" { default = "local" }

locals {
  ami_name = "myapp-${var.git_sha}-${formatdate("YYYYMMDD-hhmm", timestamp())}"
}

source "amazon-ebs" "app" {
  region        = var.region
  instance_type = "t3.small"
  ssh_username  = "ec2-user"
  ami_name      = local.ami_name

  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023.*-x86_64"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }
    owners      = ["amazon"]
    most_recent = true
  }

  tags = {
    Name   = local.ami_name
    App    = "myapp"
    GitSha = var.git_sha
  }
}

build {
  sources = ["source.amazon-ebs.app"]

  provisioner "file" {
    source      = "app/"
    destination = "/tmp/app"
  }

  provisioner "shell" {
    script = "packer/provision.sh"
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}