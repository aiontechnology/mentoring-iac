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
  log_name = "${local.resource_tag}-ui-log-group"
}

################################################################################
# Create container definition
################################################################################
resource "aws_cloudwatch_log_group" "ecs-log-group" {
  name = local.log_name
  tags = {
    Environment = var.general.environment
    Application = local.log_name
  }
}

resource "aws_ecs_task_definition" "ui" {
  family                   = "${local.resource_tag}-ui"
  task_role_arn            = var.ui.execution_role_arn
  execution_role_arn       = var.ui.execution_role_arn
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "1024"
  requires_compatibilities = ["FARGATE"]
  container_definitions = <<DEFINITION
[
  {
    "image": "661143960593.dkr.ecr.us-west-2.amazonaws.com/mentorsuccess-ui:${var.docker.tag}",
    "name": "mentorsuccess-ui",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region" : "us-west-2",
        "awslogs-group" : "${aws_cloudwatch_log_group.ecs-log-group.name}",
        "awslogs-stream-prefix" : "${local.resource_tag}-ui"
      }
    },
    "secrets": [],
    "environment": [
      {
        "name": "IS_PRODUCTION",
        "value": "true"
      },
      {
        "name": "BASE_URI",
        "value": "${var.ui.base_uri}"
      },
      {
        "name": "TOKEN_REDIRECT",
        "value": "${var.ui.token_redirect}"
      },
      {
        "name": "LOGOUT_TOKEN_REDIRECT",
        "value": "${var.ui.logout_redirect}"
      },
      {
        "name": "API_URL",
        "value": "${var.containers.service_url}"
      },
      {
        "name": "LPG_URL",
        "value": "${var.containers.lpg_url}"
      },
      {
        "name": "COGNITO_CLIENT_ID",
        "value": "${var.cognito.client_id}"
      },
      {
        "name": "COGNITO_BASE_URL",
        "value": "${var.cognito.endpoint}"
      }
    ],
    "portMappings": [
      {
        "containerPort": 80,
        "protocol": "tcp"
      }
    ]
  }

]
DEFINITION
}

################################################################################
# Create certificate
################################################################################
resource "aws_acm_certificate" "lb-certificate" {
  domain_name = var.networking.certificate_domain_name
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "${local.resource_tag}-cert"
  }
}

################################################################################
# Create load balancer
################################################################################
resource "aws_lb_target_group" "ui-tg" {
  name = "${local.resource_tag}-ui-tg"
  vpc_id = var.networking.vpc.id
  target_type = "ip"
  port = 80
  protocol = "TCP"
}

resource "aws_lb" "ui-lb" {
  name = "${local.resource_tag}-ui-lb"
  internal = false
  load_balancer_type = "network"
  subnets = var.ui.subnet_ids
}

resource "aws_lb_listener" "ui-lb-listener" {
  load_balancer_arn = aws_lb.ui-lb.arn
  port = "443"
  protocol = "TLS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.lb-certificate.arn
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.ui-tg.arn
  }
}

################################################################################
# Create ui
################################################################################
data "aws_ecs_container_definition" "ui-definition" {
  container_name = "mentorsuccess-ui"
  task_definition = aws_ecs_task_definition.ui.id
}

resource "aws_ecs_service" "mentorsuccess-ui" {
  name = "${local.resource_tag}-ui"
  cluster = var.ecs.cluster_id
  task_definition = aws_ecs_task_definition.ui.arn
  desired_count = var.ecs.desired_count
  launch_type = "FARGATE"
  network_configuration {
    subnets = var.ui.subnet_ids
    security_groups = [var.ui.sg]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.ui-tg.arn
    container_name = data.aws_ecs_container_definition.ui-definition.container_name
    container_port = 80
  }
  depends_on = [aws_lb.ui-lb]
}
