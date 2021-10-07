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

################################################################################
# Define locals
################################################################################
locals {
  resource_tag = "${var.general.name}-${var.general.environment}"
  log_name = "${local.resource_tag}-lpg-log-group"
}

################################################################################
# Create container definition
################################################################################
resource "aws_cloudwatch_log_group" "ecs-log-group" {
  tags = {
    Environment = var.general.environment
    Application = local.log_name
  }
}

resource "aws_ecs_task_definition" "lpg" {
  family                   = "${local.resource_tag}-lpg"
  task_role_arn            = var.lpg.execution_role_arn
  execution_role_arn       = var.lpg.execution_role_arn
  network_mode             = "awsvpc"
  cpu                      = var.ecs.cpu
  memory                   = var.ecs.memory
  requires_compatibilities = ["FARGATE"]
  container_definitions = <<DEFINITION
[
  {
    "image": "661143960593.dkr.ecr.us-west-2.amazonaws.com/mentorsuccess-lpg:${var.docker.tag}",
    "name": "mentorsuccess-lpg",
    "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-region" : "us-west-2",
                    "awslogs-group" : "${aws_cloudwatch_log_group.ecs-log-group.name}",
                    "awslogs-stream-prefix" : "${local.resource_tag}-lpg"
                }
            },
    "secrets": [],
    "environment": [
      {
        "name": "AMAZON_DYNAMODB_ENDPOINT",
        "value": "https://dynamodb.us-west-2.amazonaws.com"
      },
      {
        "name": "AMAZON_REGION",
        "value": "us-west-2"
      },
      {
        "name": "SPRING_PROFILES_ACTIVE",
        "value": "${var.spring.profile}"
      },
      {
        "name": "ENVIRONMENT_NAME",
        "value": "${var.general.environment}"
      },
      {
        "name": "SPRING_CLOUD_DISCOVERY_CLIENT_SIMPLE_INSTANCES_BOOKS_0_URI",
        "value": "${var.services_api_url}"
      },
      {
        "name": "SPRING_CLOUD_DISCOVERY_CLIENT_SIMPLE_INSTANCES_GAMES_0_URI",
        "value": "${var.services_api_url}"
      },
      {
        "name": "SPRING_CLOUD_DISCOVERY_CLIENT_SIMPLE_INSTANCES_SCHOOLS_0_URI",
        "value": "${var.services_api_url}"
      },
      {
        "name": "SPRING_CLOUD_DISCOVERY_CLIENT_SIMPLE_INSTANCES_STUDENTS_0_URI",
        "value": "${var.services_api_url}"
      },
      {
        "name": "SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_JWK_SET_URI",
        "value": "https://cognito-idp.${var.general.region}.amazonaws.com/${var.cognito.pool_id}/.well-known/jwks.json"
      }
    ],
    "portMappings": [
      {
        "containerPort": 8080,
        "protocol": "tcp"
      }
    ]
  }

]
DEFINITION
}

################################################################################
# Create load balancer
################################################################################
resource "aws_lb_target_group" "lpg-tg" {
  name = "${local.resource_tag}-lpg-tg"
  vpc_id = var.networking.vpc.id
  target_type = "ip"
  port = 8080
  protocol = "TCP"
}

resource "aws_lb" "lpg-lb" {
  name = "${local.resource_tag}-lpg-lb"
  internal = true
  load_balancer_type = "network"
  subnets = var.ecs.subnet_ids
}

resource "aws_lb_listener" "lpg-lb-listener" {
  load_balancer_arn = aws_lb.lpg-lb.arn
  port = 80
  protocol = "TCP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.lpg-tg.arn
  }
}


################################################################################
# Service Discovery
################################################################################
resource "aws_service_discovery_service" "service-discovery" {
  name = "${local.resource_tag}-lpg"
  dns_config {
    namespace_id = var.networking.discovery_id
    dns_records {
      ttl = 60
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
}

################################################################################
# Create service
################################################################################
data "aws_ecs_container_definition" "lpg-definition" {
  container_name = "mentorsuccess-lpg"
  task_definition = aws_ecs_task_definition.lpg.id
}

resource "aws_ecs_service" "mentorsuccess-lpg" {
  name = "${local.resource_tag}-lpg"
  cluster = var.ecs.cluster_id
  task_definition = aws_ecs_task_definition.lpg.arn
  desired_count = var.ecs.desired_count
  launch_type = "FARGATE"
  network_configuration {
    subnets = var.ecs.subnet_ids
    security_groups = [var.ecs.sg]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.lpg-tg.arn
    container_name = data.aws_ecs_container_definition.lpg-definition.container_name
    container_port = 8080
  }
  service_registries {
    registry_arn = aws_service_discovery_service.service-discovery.arn
  }
  depends_on = [aws_lb.lpg-lb]
}

################################################################################
# Create API Gateway
################################################################################
data "template_file" "swagger_definition" {
  template = file(var.lpg.open_api_path)
  vars = {
    lb_url = "http://$${stageVariables.lb_url}"
  }
}

resource "aws_api_gateway_rest_api" "rest-api" {
  name = "${local.resource_tag}-lpg-rest-api"
  description = "API for ${var.general.name} in ${var.general.environment} environment"
  body = data.template_file.swagger_definition.rendered

  endpoint_configuration {
    types = ["EDGE"]
  }

  binary_media_types = [ "*/*" ]
}

resource "aws_api_gateway_deployment" "rest-api-deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest-api.id
}

resource "aws_api_gateway_vpc_link" "rest-api-vpc-link" {
  name = "${local.resource_tag}-vpc-link"
  target_arns = [aws_lb.lpg-lb.arn]
}

resource "aws_api_gateway_stage" "rest-stage" {
  deployment_id = aws_api_gateway_deployment.rest-api-deployment.id
  rest_api_id = aws_api_gateway_rest_api.rest-api.id
  stage_name = "${local.resource_tag}-lpg-deployment"
  cache_cluster_size = "0.5"
  variables = {
    lb_url = aws_lb.lpg-lb.dns_name
    api_url = trimprefix("${aws_api_gateway_deployment.rest-api-deployment.invoke_url}${local.resource_tag}-lpg-deployment", "https://")
    vpc_link_id = aws_api_gateway_vpc_link.rest-api-vpc-link.id
  }
}

resource "aws_api_gateway_deployment" "stage-deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest-api.id
  stage_name = "${local.resource_tag}-service-deployment"
  lifecycle {
    create_before_destroy = true
  }
}
