# terraform-examples
Examples for Cassandra Terraform Code, where we're launching Cassandra in a test environment.

You can find all Terragrunt documentation [here](https://github.com/gruntwork-io/terragrunt).
This is [a great thread](https://github.com/gruntwork-io/terragrunt/issues/169) with FAQs and best practices.

## Set up your environment variables

In Terragrunt, A realm can have several environments and is usually associated with either prod or non-prod accounts. 
We chose 'test' as the environment and 'paxosdemo' as the realm.

## Terraform - IAM / VPC
These should run first (and therefore don't depend on anything in their Terragrunt) to setup the relevant VPC, subnets and iam profiles

## Terraform - Bastion
Although not mandatory, it is setup to allow access into the private VPC where Cassandra is set 

## Terraform - Cassandra
### main.tf
This file orchestrates the various aspects of setting up Cassandra: creating a Packer build, setting up security groups and ENIs (which ensure the IP doesn't change between setups) and sets up three instances.
### packer
This section defines a packer build that gets executed with the packer helper, and creates a Cassandra image by installing 
Java and Cassandra on a an AMI builder, copying the cassandra.yml file and creating a typical Cassandra instance image. 
### userdata
This section gets called once after an imaged instance has been launched, and its output can be monitored in `/var/log/cloud_init_output.log`. 
The userdata script accepts parameters (such as instance IPs) and allows Cassandra to be configured once it is up. 

## Terragrunt 
Terragrunt files typically reside in the same hierarchy as terraform. They contain a JSON that indicates the variable values they need to scrape and pass into the terraform code defined in "source"
In our example, the entire setup sits under the 'test' hierarchy. 

## Deployment Process
1. cd to desired environment folder (in this example, test)
2. run `terragrunt get` (please see note below about getting updated terraform files)
3. run `terragrunt plan`
4. run `terragrunt apply-all` to set the entire environment up, or `terragrunt apply` from a sub directory.

## How to destroy current env
1. cd to desired environment folder
2. run `terragrunt destroy-all`, or `terragrunt destroy` from a subdirectory.

## How to update the terraform files
Within terraform.tfvars, you can change the source to whatever you would like.
You can customize this using this [module sources guide](https://www.terraform.io/docs/modules/sources.html)  

For example, if you would like to specify a specific git branch you can change the source to:  
`git@github.com:paxos-bankchain/bankchain-terraform.git//modules?ref=BRANCH_NAME`

_**Please note that Terragrunt doesn't automatically pull the latest version unless the url changes.
This is the default in order to keep Terragrunt running fairly quickly. If you'd like to force an update, you can run the `terragrunt get -update=true` command._
