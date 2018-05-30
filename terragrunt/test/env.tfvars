# Root level variables that all modules can inherit. This is especially helpful with multi-account configs
# where terraform_remote_state data sources are placed directly into the modules.
# REALM LEVEL
aws_region      = "eu-west-1"
aws_profile     = "default"

tfstate_bucket = "terraform.test.state"
tfstate_region = "us-east-1"

env_name        = "test"
realm_name      = "paxosdemo"

vpc_tfstate_key = "test/vpc/terraform.tfstate"
ssh_key_name = "key-name"
