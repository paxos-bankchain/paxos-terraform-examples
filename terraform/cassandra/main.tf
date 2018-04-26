terraform {
  backend "s3" {}
}

variable "env_name" {}
variable "instance_type" {}
variable "aws_profile" {}
variable "aws_region" {}
variable "tfstate_bucket" {}
variable "vpc_tfstate_key" {}
variable "tfstate_region" {}
variable "iam_tfstate_key" {}

variable "cassandra_tokens" {
  type = "list"
}

# Path to the aws generated .pem file for sshing into other instances
variable "ssh_key_name" {}
variable "ssh_key_path" {}
variable "cassandra_ami_version" {}

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

data "terraform_remote_state" "iam" {
  backend = "s3"

  config {
    profile = "${var.aws_profile}"
    bucket  = "${var.tfstate_bucket}"
    key     = "${var.iam_tfstate_key}"
    region  = "${var.tfstate_region}"
  }
}

module "vpc_data" {
  source         = "git@github.com:paxos-bankchain/terraform-example.git//helpers/vpc-data"
  aws_profile    = "${var.aws_profile}"
  tfstate_bucket = "${var.tfstate_bucket}"
  tfstate_key    = "${var.vpc_tfstate_key}"
  tfstate_region = "${var.tfstate_region}"
}

module "cassandra_packer_build" {
  source = "git@github.com:paxos-bankchain/terraform-example.git//helpers/packer"
  ami_name = "cassandra-${var.cassandra_ami_version}"
  aws_profile = "${var.aws_profile}"
  aws_region = "${var.aws_region}"
  directory = "packer/cassandra"
}

#Commodity Cluster Setup
resource "aws_security_group" "cassandra" {
  name = "cassandra-sg"
  vpc_id = "${module.vpc_data.vpc_id}"
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${module.vpc_data.vpc_cidr_block}"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_network_interface" "cassandra_eni" {
  count = 3
  subnet_id = "${element(module.vpc_data.database_subnets, count.index)}"
  security_groups = ["${aws_security_group.cassandra.id}"]
  tags {
    name = "cassandra_eni"
    env_name = "${var.env_name}"
  }
}
data "template_file" "cassandra_userdata" {
  count = 3
  template = "${file("userdata/userdata.sh.tmpl")}"

  #Cassandra seeds are always the two first IPs in the cluster
  vars = {
    server_name = "${var.env_name}-cassandra-${count.index}"
    initial_token = "${element(var.cassandra_tokens, count.index)}"
    seed1 = "${aws_network_interface.cassandra_eni.0.private_ip}"
    seed2 = "${aws_network_interface.cassandra_eni.1.private_ip}"
    ip_self = "${element(aws_network_interface.cassandra_eni.*.private_ip, count.index)}"
    region = "${var.aws_region}"
    env_name = "${var.env_name}"
  }
}

resource "aws_instance" "cassandra-instance" {
  count = 3
  ami = "${module.cassandra_packer_build.ami_id}"
  instance_type = "${var.instance_type}"
  subnet_id = "${module.vpc_data.database_subnets[count.index]}"

  iam_instance_profile = "${data.terraform_remote_state.iam.iam_instance_cassandra_id}"
  security_groups = ["${aws_security_group.cassandra.id}"]
  key_name = "${var.ssh_key_name}"

  user_data = "${element(data.template_file.cassandra_userdata.*.rendered, count.index)}"
  tags {
    Name = "${var.env_name}-cassandra-${count.index}"
    "env_name" = "${var.env_name}"
  }
}

output "cassandra_ip_addresses" {
  value = "${aws_network_interface.cassandra_eni.*.private_ip}"
}
