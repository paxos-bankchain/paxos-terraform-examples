terraform {
  backend "s3" {}
}

variable "env_name" {}

variable "realm_name" {}
variable "aws_region" {}
variable "aws_profile" {}
variable "tfstate_bucket" {}
variable "tfstate_region" {}

locals {
  resource_prefix = "${var.realm_name}-${var.env_name}"
}

variable "single_nat_gateway" {
  default = false
}

variable "cidr" {
  default = "10.240.0.0/16"
}

variable "database_subnets" {
  type = "list"

  default = [
    "10.240.21.0/24",
    "10.240.22.0/24",
    "10.240.23.0/24",
  ]
}

variable "private_subnets" {
  type = "list"

  default = [
    "10.240.1.0/24",
    "10.240.2.0/24",
    "10.240.3.0/24",
  ]
}

variable "public_subnets" {
  type = "list"

  default = [
    "10.240.101.0/24",
    "10.240.102.0/24",
    "10.240.103.0/24",
  ]
}

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

data "aws_availability_zones" "available" {}

locals {
  azs = "${slice(data.aws_availability_zones.available.names, 0, length(var.private_subnets))}"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.resource_prefix}"
  cidr = "${var.cidr}"

  azs = "${local.azs}"

  create_database_subnet_group = true
  database_subnets             = "${var.database_subnets}"
  private_subnets              = "${var.private_subnets}"
  public_subnets               = "${var.public_subnets}"

  single_nat_gateway = true #"${var.single_nat_gateway}"

  # TODO: Is this okay?
  enable_dns_hostnames = true
  enable_nat_gateway   = true
  enable_vpn_gateway   = true
}

# Private DNS zone.
resource "aws_route53_zone" "hosted_zone" {
  name   = "${var.env_name}.${var.realm_name}"
  vpc_id = "${module.vpc.vpc_id}"
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${local.resource_prefix}-db-subnet-group"
  subnet_ids = ["${module.vpc.database_subnets}"]
}

output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "azs" {
  value = "${local.azs}"
}

output "vpc_cidr_block" {
  value = "${module.vpc.vpc_cidr_block}"
}

output "vpc_main_route_table_id" {
  value = "${module.vpc.vpc_main_route_table_id}"
}

output "private_route_table_ids" {
  value = "${module.vpc.private_route_table_ids}"
}

output "public_route_table_id" {
  value = "${module.vpc.public_route_table_ids[0]}"
}

output "private_subnets" {
  value = "${module.vpc.private_subnets}"
}

output "private_subnets_cidr_blocks" {
  value = "${module.vpc.private_subnets_cidr_blocks}"
}

output "public_subnets" {
  value = "${module.vpc.public_subnets}"
}

output "database_subnets" {
  value = "${module.vpc.database_subnets}"
}

output "public_subnets_cidr_blocks" {
  value = "${module.vpc.public_subnets_cidr_blocks}"
}

output "db_subnet_group" {
  value = "${module.vpc.database_subnet_group}"
}

output "hosted_zone_id" {
  value = "${aws_route53_zone.hosted_zone.id}"
}
