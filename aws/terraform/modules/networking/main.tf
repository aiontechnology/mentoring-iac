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
# Get the availability zones for the region
####################################################################################################
data "aws_availability_zones" "available" {}

####################################################################################################
# Define the VPC
####################################################################################################
resource "aws_vpc" "vpc"{
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${local.resource_tag}-vpc"
  }
}

####################################################################################################
# Define elastic IPs
####################################################################################################
resource "aws_eip" "nat_elastic_ip" {
  public_ipv4_pool = "amazon"

  tags = {
    Name = "${local.resource_tag}-nat-ip"
  }
}

####################################################################################################
# Define gateways
####################################################################################################
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${local.resource_tag}-ig"
  }
}

resource "aws_nat_gateway" "ecs-nat-gateway" {
  allocation_id = aws_eip.nat_elastic_ip.id
  subnet_id = aws_subnet.public1.id

  tags = {
    Name = "${local.resource_tag}-nat-gateway"
  }
}

####################################################################################################
# Define route tables
####################################################################################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }

  tags = {
    Name = "${local.resource_tag}-public-route"
  }
}

resource "aws_route_table" "ecs" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ecs-nat-gateway.id
  }

  tags = {
    Name = "${local.resource_tag}-ecs-route"
  }
}

####################################################################################################
# Define public subnets
####################################################################################################
resource "aws_subnet" "public1" {
  cidr_block = "10.0.0.0/24"
  vpc_id = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.resource_tag}-public1"
  }
}

resource "aws_route_table_association" "public1_route_association" {
  subnet_id = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "public2" {
  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.resource_tag}-public2"
  }
}

resource "aws_route_table_association" "public2_route_association" {
  subnet_id = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

####################################################################################################
# Define database subnets
####################################################################################################
resource "aws_subnet" "db1" {
  cidr_block = "10.0.2.0/24"
  vpc_id = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${local.resource_tag}-db1"
  }
}

resource "aws_subnet" "db2" {
  cidr_block = "10.0.3.0/24"
  vpc_id = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${local.resource_tag}-db2"
  }
}

####################################################################################################
# Define ecs subnets
####################################################################################################
resource "aws_subnet" "ecs1" {
  cidr_block = "10.0.4.0/24"
  vpc_id = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${local.resource_tag}-ecs1"
  }
}

resource "aws_route_table_association" "ecs1_route_association" {
  subnet_id = aws_subnet.ecs1.id
  route_table_id = aws_route_table.ecs.id
}

resource "aws_subnet" "ecs2" {
  cidr_block = "10.0.5.0/24"
  vpc_id = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${local.resource_tag}-ecs2"
  }
}

resource "aws_route_table_association" "ecs2_route_association" {
  subnet_id = aws_subnet.ecs2.id
  route_table_id = aws_route_table.ecs.id
}

####################################################################################################
# Define the security groups
####################################################################################################
resource "aws_security_group" "bastion_sg" {
  name = "ms_${var.environment}_sg_bastion"
  description = "Allow ssh access to bastion host"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "Allow connection to ssh"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound connections"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.resource_tag}-bastion-sg"
    Terraform = "networking"
  }
}

resource "aws_security_group" "ui_sg" {
  name = "ms_${var.environment}_sg_ui"
  description = "Allow web access"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "Allow connection to http"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound connections"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.resource_tag}-ui-sg"
    Terraform = "networking"
  }
}

resource "aws_security_group" "server_sg" {
  name = "ms_${var.environment}_sg_ecs"
  description = "Allow ecs access"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "Allow connection to tomcat"
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound connections"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.resource_tag}-ecs-sg"
    Terraform = "networking"
  }
}

resource "aws_security_group" "db_sg" {
  name = "ms_${var.environment}_sg_db"
  description = "Allow db access from server"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "Allow connection from services security group"
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = [aws_security_group.server_sg.id, aws_security_group.bastion_sg.id]
  }

  egress {
    description = "Allow all outbound connections"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.resource_tag}-db-sg"
    Terraform = "networking"
  }
}
