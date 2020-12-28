# Copyright 2020 Aion Technology LLC
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

module "networking" {
  source = "./modules/networking"
  name = var.name
  environment = var.environment
}

module "ecs" {
  source = "./modules/ecs"
  name = var.name
  environment = var.environment
}

module "database" {
  source = "./modules/database"
  name = var.name
  environment = var.environment
  sg  = module.networking.sg
  subnet_ids = module.networking.subnets.db_subnets
}

module "services" {
  source = "./modules/services"

  cluster_id = module.ecs.cluster_id
  db_config = module.database.db_config
  docker_tag = var.docker_tag
  environment = var.environment
  execution_role_arn = module.ecs.service-execution-role.arn
  name = var.name
  openapi_path = var.server_openapi_path
  sg = module.networking.sg
  subnet_ids = module.networking.subnets.ecs_subnets
  vpc = module.networking.vpc
  discovery_id = module.networking.discovery.id
}

module "security" {
  source = "./modules/security"
  name = var.name
  environment = var.environment
  token_redirect = var.token_redirect
  logout_redirect = var.logout_redirect
  public_key = var.public_key
  sg = module.networking.sg
  subnet_ids = module.networking.subnets.public_subnets
}

module "ui" {
  source = "./modules/ui"

  api_url = module.services.api_url
  certificate_domain_name = var.certificate_domain_name
  cluster_id = module.ecs.cluster_id
  cognito_base_url = module.security.cognito_endpoint
  cognito_client_id = module.security.cognito_client_id
  docker_tag = var.docker_tag
  environment = var.environment
  execution_role_arn = module.ecs.service-execution-role.arn
  logout_redirect = var.logout_redirect
  name = var.name
  sg = module.networking.sg
  subnet_ids = module.networking.subnets.public_subnets
  token_redirect = var.token_redirect
  vpc = module.networking.vpc
}

module "lpg" {
  source = "./modules/lpg"

  cluster_id = module.ecs.cluster_id
  docker_tag = var.docker_tag
  environment = var.environment
  execution_role_arn = module.ecs.lpg-execution-role.arn
  name = var.name
  openapi_path = var.lpg_openapi_path
  sg = module.networking.sg
  subnet_ids = module.networking.subnets.ecs_subnets
  vpc = module.networking.vpc
  discovery_id = module.networking.discovery.id
}
