# Copyright 2020-2021 Aion Technology LLC
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
  resource_tag = "${var.name}-${var.environment}"
}

################################################################################
# Create container definition
################################################################################
resource "aws_cloudwatch_log_group" "ecs-log-group" {
  name = "${local.resource_tag}-server-log-group"

  tags = {
    Environment = "var.environment"
    Application = "var.name"
  }
}

resource "aws_ecs_task_definition" "server" {
  family                   = "${local.resource_tag}-server"
  task_role_arn            = var.execution_role_arn
  execution_role_arn       = var.execution_role_arn
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "1024"
  requires_compatibilities = ["FARGATE"]
  container_definitions = <<DEFINITION
[
  {
    "image": "661143960593.dkr.ecr.${var.region}.amazonaws.com/mentorsuccess-server:${var.docker_tag}",
    "name": "mentorsuccess-server",
    "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-region" : "${var.region}",
                    "awslogs-group" : "${aws_cloudwatch_log_group.ecs-log-group.name}",
                    "awslogs-stream-prefix" : "${local.resource_tag}-server"
                }
            },
    "secrets": [],
    "environment": [
      {
        "name": "SPRING_DATASOURCE_URL",
        "value": "jdbc:postgresql://${var.db_config.endpoint}/mentorsuccess"
      },
      {
        "name": "SPRING_DATASOURCE_PASSWORD",
        "value": "${var.db_config.password}"
      },
      {
        "name": "SPRING_PROFILES_ACTIVE",
        "value": "${var.environment}"
      },
      {
        "name": "SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_JWK_SET_URI",
        "value": "https://cognito-idp.${var.region}.amazonaws.com/${var.cognito_pool_id}/.well-known/jwks.json"
      },
      {
        "name": "AWS_COGNITO_USERPOOLID",
        "value": "${var.cognito_pool_id}"
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
resource "aws_lb_target_group" "server-tg" {
  name = "${local.resource_tag}-server-tg"
  vpc_id = var.vpc.id
  target_type = "ip"
  port = 8080
  protocol = "TCP"
}

resource "aws_lb" "server-lb" {
  name = "${local.resource_tag}-server-lb"
  internal = true
  load_balancer_type = "network"
  subnets = var.subnet_ids
}

resource "aws_lb_listener" "server-lb-listener" {
  load_balancer_arn = aws_lb.server-lb.arn
  port = 80
  protocol = "TCP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.server-tg.arn
  }
}

################################################################################
# Service Discovery
################################################################################
resource "aws_service_discovery_service" "service-discovery" {
  name = "${local.resource_tag}-server"
  dns_config {
    namespace_id = var.discovery_id
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
data "aws_ecs_container_definition" "server-definition" {
  container_name = "mentorsuccess-server"
  task_definition = aws_ecs_task_definition.server.id
}

resource "aws_ecs_service" "mentorsuccess-server" {
  name = "${local.resource_tag}-server"
  cluster = var.cluster_id
  task_definition = aws_ecs_task_definition.server.arn
  desired_count = 1
  launch_type = "FARGATE"
  network_configuration {
    subnets = var.subnet_ids
    security_groups = [var.sg.server]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.server-tg.arn
    container_name = data.aws_ecs_container_definition.server-definition.container_name
    container_port = 8080
  }
  service_registries {
    registry_arn = aws_service_discovery_service.service-discovery.arn
  }
  depends_on = [aws_lb.server-lb]
}

################################################################################
# Create API Gateway
################################################################################
data "template_file" "swagger_definition" {
  template = file(var.openapi_path)
  vars = {
    lb_url = "http://$${stageVariables.lb_url}"
  }
}

resource "aws_api_gateway_rest_api" "rest-api" {
  name = "${local.resource_tag}-service-rest-api"
  description = "API for ${var.name} in ${var.environment} environment"
  body = data.template_file.swagger_definition.rendered

  endpoint_configuration {
    types = ["EDGE"]
  }
}

resource "aws_api_gateway_deployment" "rest-api-deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest-api.id
}

resource "aws_api_gateway_vpc_link" "rest-api-vpc-link" {
  name = "${local.resource_tag}-vpc-link"
  target_arns = [aws_lb.server-lb.arn]
}

resource "aws_api_gateway_stage" "rest-stage" {
  deployment_id = aws_api_gateway_deployment.rest-api-deployment.id
  rest_api_id = aws_api_gateway_rest_api.rest-api.id
  stage_name = "${local.resource_tag}-service-deployment"
  variables = {
    lb_url = aws_lb.server-lb.dns_name
    api_url = trimprefix("${aws_api_gateway_deployment.rest-api-deployment.invoke_url}${local.resource_tag}-service-deployment", "https://")
    vpc_link_id = aws_api_gateway_vpc_link.rest-api-vpc-link.id
  }
}
