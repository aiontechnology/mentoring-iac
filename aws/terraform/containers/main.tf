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

module "services" {
  source = "./modules/services"

  cognito = var.cognito
  db = var.db
  docker = var.docker
  ecs = var.ecs
  general = var.general
  networking = var.networking
  service = var.service
  spring = var.spring
  email = var.email
}

module "lpg" {
  source = "./modules/lpg"

  cognito = var.cognito
  docker = var.docker
  ecs = var.ecs
  general = var.general
  lpg = var.lpg
  networking = var.networking
  services_api_url = module.services.api_lb_url
  spring = var.spring
}

module ui {
  source = "./modules/ui"

  cognito = var.cognito
  containers = {
    lpg_url = module.lpg.api_url
    service_url = module.services.api_url
  }
  docker = var.docker
  ecs = var.ecs
  general = var.general
  networking = var.networking
  ui = var.ui
}
