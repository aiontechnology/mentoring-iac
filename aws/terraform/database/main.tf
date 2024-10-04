# Copyright 2021-2024 Aion Technology LLC
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
  db_password = random_id.random_16.b64_url
  resource_tag = "${var.general.name}-${var.general.environment}"
}

################################################################################
# Define Postgres database
################################################################################
resource "random_id" "random_16" {
  byte_length = 16 * 3 / 4
}

resource "aws_db_subnet_group" "db_subnet_group" {
  subnet_ids = var.db.subnet_ids
}

resource "aws_db_instance" "database" {
  allocated_storage = 10
  engine = "postgres"
  engine_version = var.db.engine_version
  instance_class = var.db.class
  identifier = "${local.resource_tag}-db-instance"
  username = "postgres"
  password = local.db_password
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [var.db.sg]
  skip_final_snapshot = true
  apply_immediately = true
  backup_window = "11:27-11:57"
  backup_retention_period = 7
  delete_automated_backups = true
  deletion_protection = var.db.is_protected
}
