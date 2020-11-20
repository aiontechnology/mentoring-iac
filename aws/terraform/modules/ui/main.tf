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

####################################################################################################
# Define locals
####################################################################################################
locals {
  resource_tag = "${var.name}-${var.environment}"
}

####################################################################################################
# Create container definition
####################################################################################################
resource "aws_cloudwatch_log_group" "ecs-log-group" {
  name = "${local.resource_tag}-ui-log-group"

  tags = {
    Environment = var.environment
    Application = var.name
  }
}

resource "aws_ecs_task_definition" "ui" {
  family                   = "${local.resource_tag}-ui"
  task_role_arn            = var.execution_role_arn
  execution_role_arn       = var.execution_role_arn
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "1024"
  requires_compatibilities = ["FARGATE"]
  container_definitions = <<DEFINITION
[
  {
    "image": "661143960593.dkr.ecr.us-west-2.amazonaws.com/mentorsuccess-ui:${var.docker_tag}",
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
        "name": "TOKEN_REDIRECT",
        "value": "${var.token_redirect}"
      },
      {
        "name": "LOGOUT_REDIRECT",
        "value": "${var.logout_redirect}"
      },
      {
        "name": "API_URL",
        "value": "${var.api_url}"
      },
      {
        "name": "COGNITO_CLIENT_ID",
        "value": "${var.cognito_client_id}"
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

####################################################################################################
# Create certificate
####################################################################################################
resource "aws_acm_certificate" "lb-certificate" {
  domain_name = var.certificate_domain_name
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "${local.resource_tag}-cert"
  }
}

####################################################################################################
# Create load balancer
####################################################################################################
resource "aws_lb_target_group" "ui-tg" {
  name = "${local.resource_tag}-ui-tg"
  vpc_id = var.vpc.id
  target_type = "ip"
  port = 80
  protocol = "TCP"
}

resource "aws_lb" "ui-lb" {
  name = "${local.resource_tag}-ui-lb"
  internal = false
  load_balancer_type = "network"
  subnets = var.subnet_ids
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

####################################################################################################
# Create ui
####################################################################################################
data "aws_ecs_container_definition" "ui-definition" {
  container_name = "mentorsuccess-ui"
  task_definition = aws_ecs_task_definition.ui.id
}

resource "aws_ecs_service" "mentorsuccess-ui" {
  name = "${local.resource_tag}-ui"
  cluster = var.cluster_id
  task_definition = aws_ecs_task_definition.ui.arn
  desired_count = 1
  launch_type = "FARGATE"
  network_configuration {
    subnets = var.subnet_ids
    security_groups = [var.sg.ui]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.ui-tg.arn
    container_name = data.aws_ecs_container_definition.ui-definition.container_name
    container_port = 80
  }
  depends_on = [aws_lb.ui-lb]
}
