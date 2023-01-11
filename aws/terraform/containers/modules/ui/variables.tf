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
    pool_id = string
    client_id = string
    pool_id = string
  })
}
####################################################################################################
# Containers configuration
####################################################################################################
variable "containers" {
  type = object({
    lpg_url = string
    service_url = string
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
  type = object({
    environment = string,
    name = string,
    region = string
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
# UI configuration
####################################################################################################
variable "ui" {
  description = "Configuration for the UI container"
  type = object({
    base_uri = string
    execution_role_arn = string
    subnet_ids = list(string)
    sg = string
  })
}
