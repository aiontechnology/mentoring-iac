# About #

This project contains environment specific artifacts for the MentorSuccess
project. Specifically, there are Terraform scripts that can be used to set
up environments in which the MentorSuccess code will run.

# Configuration #

The following variable need to be defined for the scripts to run:

* certificate_domain_name - The domain name for the environment
* docker_tag - The Docker tag of the artifact builds to use
* environment - The name of the environment
* token_redirect - The URL that Cognito calls with a token
* logout_redirect - The URL that Cognito calls after a logout
* public_key - A public key for log into the bastion host
* openapi_path - The path to the OpenApi definition on the local filesystem
