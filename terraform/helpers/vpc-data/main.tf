# vpc-data-helper is a module wrapping the remote state of a VPC module.

variable "aws_profile" {}
variable "tfstate_bucket" {}
variable "tfstate_region" {}
variable "tfstate_key" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket  = "${var.tfstate_bucket}"
    region  = "${var.tfstate_region}"
    key     = "${var.tfstate_key}"
    profile = "${var.aws_profile}"
  }
}

output "vpc_id" {
  value = "${data.terraform_remote_state.vpc.vpc_id}"
}

output "azs" {
  value = "${data.terraform_remote_state.vpc.azs}"
}

output "realm_cidr" {
  value = "${data.terraform_remote_state.vpc.realm_cidr}"
}

output "vpc_cidr_block" {
  value = "${data.terraform_remote_state.vpc.vpc_cidr_block}"
}

output "vpc_main_route_table_id" {
  value = "${data.terraform_remote_state.vpc.vpc_main_route_table_id}"
}

output "private_route_table_ids" {
  value = "${data.terraform_remote_state.vpc.private_route_table_ids}"
}

output "public_route_table_id" {
  value = "${data.terraform_remote_state.vpc.public_route_table_id}"
}

output "private_subnets" {
  value = "${data.terraform_remote_state.vpc.private_subnets}"
}

output "private_subnets_cidr_blocks" {
  value = "${data.terraform_remote_state.vpc.private_subnets_cidr_blocks}"
}

output "public_subnets" {
  value = "${data.terraform_remote_state.vpc.public_subnets}"
}

output "public_subnets_cidr_blocks" {
  value = "${data.terraform_remote_state.vpc.public_subnets_cidr_blocks}"
}

output "database_subnets" {
  value = "${data.terraform_remote_state.vpc.database_subnets}"
}

output "database_subnets_cidr_blocks" {
  value = "${data.terraform_remote_state.vpc.database_subnets_cidr_blocks}"
}

output "db_subnet_group" {
  value = "${data.terraform_remote_state.vpc.db_subnet_group}"
}

output "elasticache_subnet_group" {
  value = "${data.terraform_remote_state.vpc.elasticache_subnet_group}"
}

output "hosted_zone_id" {
  value = "${data.terraform_remote_state.vpc.hosted_zone_id}"
}

output "dns_server" {
  value = "${data.terraform_remote_state.vpc.dns_server}"
}
