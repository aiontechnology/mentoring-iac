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
}

################################################################################
# Define Cognito
################################################################################
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
  schema {
    name = "school_uuid"
    attribute_data_type = "String"
    developer_only_attribute = false
    mutable = true
    required = false
    string_attribute_constraints {
      min_length = 0
      max_length = 255
    }
  }
  admin_create_user_config {
    allow_admin_create_user_only = true
    invite_message_template {
      email_subject = "Your new MentorSuccess account"
      email_message = <<EOF
<img src="https://mentorsuccess-public.s3.us-west-2.amazonaws.com/email-logo.png"></img>
<p>
Hello,
<p>
Welcome to MentorSuccess™. Your new account has been created. Please log in <a href="https://test.mentorsuccess.aiontechnology.io/">here</a>.
<p>
Your temporary credentials are
<br>&nbsp;&nbsp;&nbsp;&nbsp;Username: {username}
<br>&nbsp;&nbsp;&nbsp;&nbsp;Password: {####}
<p>
You will be required to change them when you log in.
<p>
Thank You!
<br>MentorSuccess™
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
  read_attributes = [ "custom:school_uuid" ]
  callback_urls = [var.cognito.token_redirect]
  logout_urls = [var.cognito.logout_redirect]
}

resource "aws_cognito_user_pool_domain" "user_pool_domain" {
  domain = "mentorsuccess-${local.resource_tag}"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

resource "aws_cognito_user_group" "system_admin" {
  name = "SYSTEM_ADMIN"
  description = "System Administrator"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

resource "aws_cognito_user_group" "program_admin" {
  name = "PROGRAM_ADMIN"
  description = "Program Administrator"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}
