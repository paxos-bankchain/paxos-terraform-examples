# Root level variables that all modules can inherit. This is especially helpful with multi-account configs
# where terraform_remote_state data sources are placed directly into the modules.
# REALM LEVEL
realm_name      = "bcmetalsnonprod"
realm_domain    = "bcmetalsnonprod.com"
# https://docs.google.com/spreadsheets/d/1H_Hhs5tImKP4CYnIk7TAq2hrC8UMKGH9v8frQuidYMY/edit
realm_cidr_slot = 9
external_domain = "metals.bankchainnonprod.com"
external_hosted_zone = "bankchainnonprod.com"
external_hosted_zone_id = "ZSSNSYVODYMO"
aws_region      = "eu-west-1"
aws_profile     = "bcnonprod"

tfstate_bucket = "terraform.bcmetalsnonprod"
tfstate_region = "us-east-1"

# By default, don't use an instance SSH key.
ssh_key_name = ""

mgmt_iam_tfstate_key = "mgmt/iam/terraform.tfstate"
vault_tls_tfstate_key = "mgmt-core/vault-tls-init/terraform.tfstate"
mgmt_vpc_tfstate_key = "mgmt-core/vpc/terraform.tfstate"
vault_tfstate_key = "mgmt/vault-data/realm/terraform.tfstate"
admin_iam_tfstate_key     = "mgmt/admin-iam/terraform.tfstate"

//All AMI versions should be the same across the realm
vault_ami_version = 6
consul_ami_version = 4
cassandra_ami_version = 15
kafka_ami_version = 8
zookeeper_ami_version = 12
burrow_ami_version = 16
prometheus_ami_version = 1

# All created VPCs should only use one NAT gateway in this realm.
# (as opposed to one per AZ)
single_nat_gateway = 1
