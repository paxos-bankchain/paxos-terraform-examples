terraform {
  backend "s3" {}
}

variable "realm_name" {}
variable "aws_region" {}
variable "aws_profile" {}

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

variable "env_name" {}
variable "instance_type" {}
variable "tfstate_bucket" {}
variable "vpc_tfstate_key" {}
variable "tfstate_region" {}

variable "ssh_key_name" {}

data "aws_ami" "ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2017.12.0.20180109-x86_64-ebs"]
  }
}

locals {
  name = "${var.realm_name}-${var.env_name}-bastion"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket  = "${var.tfstate_bucket}"
    region  = "${var.tfstate_region}"
    key     = "${var.vpc_tfstate_key}"
    profile = "${var.aws_profile}"
  }
}

# The security groups are liberal for this example, and need to be specific to your access needs
resource "aws_security_group" "bastion" {
  name   = "bastion-sg"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # To be populated according to requirements
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # To be populated according to requirements
  }
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${local.name}"
  role = "${var.realm_name}-${var.env_name}-service-bastion"
}

resource "aws_instance" "bastion" {
  ami = "${data.aws_ami.ami.id}"

  instance_type = "${var.instance_type}"
  subnet_id     = "${data.terraform_remote_state.vpc.public_subnets[0]}"

  iam_instance_profile   = "${aws_iam_instance_profile.bastion.id}"
  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]
  key_name               = "${var.ssh_key_name}"

  tags {
    Name     = "${local.name}"
    env_name = "${var.env_name}"
  }
}

output "public_ip" {
  value = "${aws_instance.bastion.public_ip}"
}
