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

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.user_pool_client.id
}

output "cognito_endpoint" {
  value = "mentorsuccess-${local.resource_tag}.auth.us-west-2.amazoncognito.com"
}

output "cognito_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}
