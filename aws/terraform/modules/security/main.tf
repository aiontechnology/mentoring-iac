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
# Define Cognito
####################################################################################################
resource "aws_cognito_user_pool" "user_pool" {
  name = "${local.resource_tag}-user-pool"
  username_configuration {
    case_sensitive = false
  }
  username_attributes = ["email", "phone_number"]
  schema {
    name = "family_name"
    attribute_data_type = "String"
    developer_only_attribute = false
    mutable = true
    required = true
    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }
  schema {
    name = "given_name"
    attribute_data_type = "String"
    developer_only_attribute = false
    mutable = true
    required = true
    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }
  admin_create_user_config {
    allow_admin_create_user_only = true
    invite_message_template {
      email_subject = "MentorSuccess Account"
      email_message = <<EOF
Hello. Your MentorSuccess account has been created. Your username is {username}. Your temporary password is {####}. You will be required to change it when you log in.
      EOF
      sms_message = "Your MentorSuccess username is {username} and temporary password is {####}. "
    }
  }
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name = "${local.resource_tag}-user-pool-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  supported_identity_providers = ["COGNITO"]
  allowed_oauth_flows = ["implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = ["openid", "profile"]
  callback_urls = [var.token_redirect]
  logout_urls = [var.logout_redirect]
}

resource "aws_cognito_user_pool_domain" "user_pool_domain" {
  domain = "mentorsuccess-${local.resource_tag}"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

####################################################################################################
# Define bastion host
####################################################################################################
resource "aws_key_pair" "bastion-keypair" {
  key_name = "${var.environment}-bastion-keypair"
  public_key = var.public_key
}

resource "aws_instance" "bastion" {
  ami = "ami-0d6621c01e8c2de2c"
  instance_type = "t2.micro"
  subnet_id = var.subnet_ids[0]
  vpc_security_group_ids = [var.sg.bastion]
  key_name = aws_key_pair.bastion-keypair.key_name
  tags = {
    Name = "${local.resource_tag}-bastion"
  }
}