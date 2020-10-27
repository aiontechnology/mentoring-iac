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

output "sg" {
  value = {
    db = aws_security_group.db_sg.id
    server = aws_security_group.server_sg.id
    ui = aws_security_group.ui_sg.id
    bastion = aws_security_group.bastion_sg.id
  }
}

output "subnets" {
  value = {
    db_subnets = [aws_subnet.db1.id, aws_subnet.db2.id]
    ecs_subnets = [aws_subnet.ecs1.id, aws_subnet.ecs2.id]
    public_subnets = [aws_subnet.public1.id, aws_subnet.public2.id]
  }
}

output "vpc" {
  value = aws_vpc.vpc
}
