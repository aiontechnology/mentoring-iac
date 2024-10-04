####################################################################################################
# Cognito configuration
####################################################################################################
variable "cognito" {
  description = "Configuration for the Cognito pool. This info should be from the Cognito script."
  type = object({
    client_id = string
    endpoint = string
    pool_id = string
  })
}

####################################################################################################
# Database configuration. This information is generated by the database script and must be copied
# here.
####################################################################################################
variable "db" {
  description = "Configuration for the database. This info should come from the database script."
  type = object({
    endpoint = string
    password = string
  })
}

####################################################################################################
# Docker configuration
####################################################################################################
variable "docker" {
  description = "Configuration for docker."
  type = object({
    tag = string
  })
}

####################################################################################################
# ECS configuration
####################################################################################################
variable "ecs" {
  description = "Configuration for the ECS environment. This info should come from the ecs script."
  type = object({
    cluster_id = string
    cpu = string
    desired_count = number
    memory = string
    subnet_ids = list(string)
    sg = string
  })
}

####################################################################################################
# General configuration
####################################################################################################
variable "general" {
  description = "General configuration."
  type = object({
    environment = string
    name = string
    region = string
  })

  default = {
    environment = "test"
    name = "unset"
    region = "us-west-2"
  }
}

####################################################################################################
# LPG configuration
####################################################################################################
variable "lpg" {
  description = "Configuration for the LPG container."
  type = object({
    execution_role_arn = string
    open_api_path = string
  })
}

####################################################################################################
# Networking configuration
####################################################################################################
variable "networking" {
  description = "Configuration for networking. This info should come from the networking script."
  type = object({
    certificate_domain_name = string
    discovery_id = string
    vpc = object({
      id = string
    })
  })
}

####################################################################################################
# Service configuration
####################################################################################################
variable "service" {
  description = "Configuration for the service container."
  type = object({
    execution_role_arn = string
    open_api_path = string
  })
}

####################################################################################################
# Spring related configuration
####################################################################################################
variable "spring" {
  description = "Spring configuration."
  type = object({
    profile = string
  })
}

####################################################################################################
# Email related configuration
####################################################################################################
variable "email" {
  description = "Email server configuration."
  type = object({
    username = string
    password = string
  })
}

####################################################################################################
# UI configuration
####################################################################################################
variable "ui" {
  description = "Configuration for the UI container"
  type = object({
    base_uri = string
    execution_role_arn = string
    logout_redirect = string
    subnet_ids = list(string)
    sg = string
    token_redirect = string
  })
}
