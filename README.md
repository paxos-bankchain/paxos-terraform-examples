# terraform-examples
Examples for Cassandra Terraform Code

This repo holds the variables needed to launch terraform modules in different environments.
As an example, we're launching Cassandra in a test environment.

You can find all Terragrunt documentation [here](https://github.com/gruntwork-io/terragrunt).
This is [a great thread](https://github.com/gruntwork-io/terragrunt/issues/169) with FAQs and best practices.

## Set up your environment variables

A realm can have several environments and is usually associated with either prod or non-prod accounts. 
We chose 'test' as the environment and 'paxosdemo' as the realm.

## Test Deploy Procedure

Note that if you want to use your local copy of the bankchain-terraform or common-terraform repo, you should pass `--terragrunt-source` to all terragrunt commands + deploy scripts below.
All script paths below are relative to the repo root directory, but the scripts can be invoked from anywhere.

## Deploy Process
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
