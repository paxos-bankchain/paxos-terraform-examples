terraform {
  backend "s3" {}
}

# AWS settings
variable "aws_profile" {}

variable "aws_region" {}

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

# S3 bucket settings
variable "tfstate_region" {}

variable "tfstate_bucket" {}
variable "vpc_tfstate_key" {}

# Environment Variables
variable "env_name" {}

variable "realm_name" {}

# Cassandra isntance settings
variable "instance_type" {}

variable "ssh_key_name" {}

locals {
  name = "${var.realm_name}-${var.env_name}-cassandra"
}

# Getting VPC settings from S3
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket  = "${var.tfstate_bucket}"
    region  = "${var.tfstate_region}"
    key     = "${var.vpc_tfstate_key}"
    profile = "${var.aws_profile}"
  }
}

# Create a cassandra packer image.
# By default, the helper checks for changes in the image.json file.
# Hashing the .yaml amd .repo into the builder will ensure  a new image is built every time one of these changed.
# If no image is built, the helper will just return the old image.
module "cassandra_packer_build" {
  source      = "git@github.com:paxos-bankchain/terraform-examples.git//terraform/helpers/packer"
  ami_name    = "cassandra-ami-latest"
  aws_profile = "${var.aws_profile}"
  aws_region  = "${var.aws_region}"
  directory   = "packer/cassandra"

  extra_vars = {
    # Include install script hash in hash appended to name.
    cassandra_yaml_hash = "${sha1(file("${path.module}/packer/cassandra/cassandra.yaml"))}"
    cassandra_repo_hash = "${sha1(file("${path.module}/packer/cassandra/cassandra.repo"))}"
  }
}

# The security groups are liberal for this example, and need to be specific to your access needs
resource "aws_security_group" "cassandra" {
  name   = "cassandra-sg"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] #To be populated according to requirements
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] #To be populated according to requirements
  }
}

# ENI: Network interface for IP allocation
resource "aws_network_interface" "cassandra_eni" {
  count           = 3
  subnet_id       = "${element(data.terraform_remote_state.vpc.database_subnets, count.index)}"
  security_groups = ["${aws_security_group.cassandra.id}"]

  tags {
    name     = "cassandra_eni"
    env_name = "${var.env_name}"
  }
}

# Userdata runs once upon machine setup
data "template_file" "cassandra_userdata" {
  count    = 3
  template = "${file("userdata/userdata.sh.tmpl")}"

  # Cassandra seeds are always the two first IPs in the cluster
  vars = {
    server_name   = "${var.env_name}-cassandra-${count.index}"
    seed1         = "${aws_network_interface.cassandra_eni.0.private_ip}"
    seed2         = "${aws_network_interface.cassandra_eni.1.private_ip}"
    region        = "${var.aws_region}"
    env_name      = "${var.env_name}"
  }
}

# IAM Profile name
resource "aws_iam_instance_profile" "cassandra" {
  name = "${local.name}"
  role = "${var.realm_name}-${var.env_name}-service-cassandra"
}

# Creating three cassandra instances and setting the cluster to work with the user_data above
resource "aws_instance" "cassandra_instance" {
  count         = 3
  ami           = "${module.cassandra_packer_build.ami_id}"
  instance_type = "${var.instance_type}"
  subnet_id     = "${data.terraform_remote_state.vpc.database_subnets[count.index]}"

  iam_instance_profile = "${aws_iam_instance_profile.cassandra.id}"
  security_groups      = ["${aws_security_group.cassandra.id}"]
  key_name             = "${var.ssh_key_name}"

  user_data = "${element(data.template_file.cassandra_userdata.*.rendered, count.index)}"

  tags {
    Name       = "${var.env_name}-cassandra-${count.index}"
    "env_name" = "${var.env_name}"
  }
}

# Output (to terminal and S3)
output "cassandra_ip_addresses" {
  value = "${aws_network_interface.cassandra_eni.*.private_ip}"
}
