#
# We do not want to disclose our partner's IP addresses, so we put them into a JSON file
# which is not under version control. It must be named "client_cidr_blocks.json" and
# has the following format:
#
# [
#   {
#       "description": "access for partner1",
#       "cidr_ipv4": "1.2.3.4/32"
#   }
# ]
#
# For each entry in this list, security group rules for InfluxDB and the registrar
# will be created to allow access.
#


locals {
  security_groups = [
    {
      id   = aws_security_group.influxdb-task.id
      port = var.influxdb_container_port
    },
    #        {
    #            id = aws_security_group.mariadb.id
    #            port = var.mariadb_container_port
    #        },
    {
      id   = aws_security_group.registrar-task.id
      port = var.registrar_container_port
    },
    {
      id   = aws_security_group.ui-task.id
      port = var.ui_container_port
    },
    {
      id   = aws_security_group.jupyter-lab-task.id
      port = var.jupyter_lab_container_port
    },
    {
      id   = aws_security_group.telegraf_promrvc-task.id
      port = var.telegraf_promrvc_container_port
    }
  ]
  client_cidr_blocks = try(jsondecode(file("client_cidr_blocks.json")), [])
  client_rules       = setproduct(local.security_groups, local.client_cidr_blocks)
}

resource "aws_vpc_security_group_ingress_rule" "client" {
  count             = length(local.client_rules)
  security_group_id = local.client_rules[count.index][0].id
  from_port         = local.client_rules[count.index][0].port
  to_port           = local.client_rules[count.index][0].port
  cidr_ipv4         = local.client_rules[count.index][1].cidr_ipv4
  ip_protocol       = "tcp"
  description       = local.client_rules[count.index][1].description
}
