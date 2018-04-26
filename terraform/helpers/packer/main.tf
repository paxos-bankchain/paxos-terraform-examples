# Utility module for executing a Packer build and surfacing the resulting AMI
# ID as an output.
# The Packer template must accept vpc, subnet, and aws_profile, and ami_name
# as input variables, and the template file must be named "image.json".
# The build is excecuted in one of the subnets in the default VPC of the
# profile region.

variable "aws_profile" {
  description = "The AWS profile to use."
}

variable "aws_region" {
  description = "The AWS region to use."
}

variable "directory" {
  description = "The directory in which to invoke Packer."
}

variable "ami_name" {
  description = "The built AMI name. Change to rebuild."
}

variable "extra_vars" {
  description = "A string-string map of extra vars to pass with '-var'"
  type        = "map"
  default     = {}
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = "${data.aws_vpc.default.id}"
}

# Don't rebuild if an existing AMI with the name exists.
data "aws_ami_ids" "existing_ami" {
  owners = ["self"]

  filter {
    name   = "name"
    values = ["${var.ami_name}"]
  }
}

locals {
  build_count     = "${length(data.aws_ami_ids.existing_ami.ids) == 0 ? 1 : 0}"
  existing_ami_id = "${element(concat(data.aws_ami_ids.existing_ami.ids, list("")), 0)}"
  extra_var_args  = "${formatlist("-var %s=\"%s\"", keys(var.extra_vars), values(var.extra_vars))}"
}

resource "null_resource" "packer_build" {
  count = "${local.build_count}"

  triggers = {
    ami_name = "${var.ami_name}"
  }

  provisioner "local-exec" {
    command = <<EOF
cd ${var.directory} && packer build \
  -var aws_profile=${var.aws_profile} \
  -var aws_region=${var.aws_region} \
  -var ami_name=${var.ami_name} \
  -var vpc=${data.aws_vpc.default.id} \
  -var subnet=${data.aws_subnet_ids.default.ids[0]} \
  ${join(" \\\n  ", local.extra_var_args)} \
  image.json \
&& sleep 10
EOF
  }
}

data "aws_ami" "built_ami" {
  count = "${local.build_count}"

  depends_on = ["null_resource.packer_build"]

  filter {
    name   = "name"
    values = ["${var.ami_name}"]
  }
}

locals {
  built_ami_id = "${element(concat(data.aws_ami.built_ami.*.id, list("")), 0)}"
}

output "ami_id" {
  value = "${coalesce(local.existing_ami_id, local.built_ami_id)}"
}
