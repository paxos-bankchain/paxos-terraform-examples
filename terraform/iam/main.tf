variable "aws_region" {}
variable "aws_profile" {}

terraform {
  backend "s3" {}
}

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

variable "realm_name" {}
variable "env_name" {}

locals {
  resource_prefix = "${var.realm_name}-${var.env_name}"
}

data "aws_iam_policy_document" "auto_attach" {
  statement {
    actions = [
      "ec2:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:AttachNetworkInterface",
      "ec2:DettachNetworkInterface",
      "ec2:DescribeVolumes",
      "ec2:AttachVolume",
    ]

    resources = [
      "*",
    ]

    effect = "Allow"
  }
}

resource "aws_iam_policy" "auto_attach" {
  name   = "${local.resource_prefix}-auto-attach"
  policy = "${data.aws_iam_policy_document.auto_attach.json}"
}

module "bastion" {
  source             = "git@github.com:paxos-bankchain/terraform-examples.git//terraform/helpers/service-iam-role"
  name               = "bastion"
  resource_prefix    = "${local.resource_prefix}"
  extra_policy_count = 0
}

# Service roles.
module "cassandra" {
  source             = "git@github.com:paxos-bankchain/terraform-examples.git//terraform/helpers/service-iam-role"
  name               = "cassandra"
  resource_prefix    = "${local.resource_prefix}"
  extra_policy_count = 1
  extra_policy_arns  = ["${aws_iam_policy.auto_attach.arn}"]
}
