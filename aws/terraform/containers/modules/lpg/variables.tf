# Copyright 2021 Aion Technology LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
# Docker configuration
####################################################################################################
variable "docker" {
  type = object({
    tag = string
  })
}

####################################################################################################
# ECS configuration
####################################################################################################
variable "ecs" {
  type = object({
    cluster_id = string,
    cpu = string,
    desired_count = number,
    memory = string,
    subnet_ids = list(string),
    sg = string
  })
}

####################################################################################################
# General configuration
####################################################################################################
variable "general" {
  type = object({
    environment = string,
    name = string,
    region = string
  })
}

####################################################################################################
# LPG configuration
####################################################################################################
variable "lpg" {
  type = object({
    execution_role_arn = string,
    open_api_path = string
  })
}

####################################################################################################
# Networking configuration
####################################################################################################
variable "networking" {
  type = object({
    certificate_domain_name = string
    discovery_id = string,
    vpc = object({
      id = string
    })
  })
}

####################################################################################################
# The URL of the main services API gateway.
####################################################################################################
variable "services_api_url" {
  type = string
}

####################################################################################################
# Spring related configuration
####################################################################################################
variable "spring" {
  type = object({
    profile = string
  })
}

