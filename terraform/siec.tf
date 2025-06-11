# EC2 instance to scrape metrics from SIEC partners

resource "aws_secretsmanager_secret" "xion-ip-to-server-mapping" {
  name = "${var.namespace}-${var.stage}-ip-to-server-mapping"
}

resource "aws_eip" "siec" {
  domain = "vpc"
  tags = {
    Name = "${var.namespace}-${var.stage}-siec-scraper-eip"
  }
}

resource "aws_eip_association" "siec" {
  instance_id         = aws_instance.siec.id
  allocation_id       = aws_eip.siec.id
  allow_reassociation = true
}


resource "aws_iam_role" "siec" {
  name = "${var.namespace}-${var.stage}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "siec" {
  name = "secrets-manager"
  role = aws_iam_role.siec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect = "Allow"
        Resource = [
          aws_secretsmanager_secret.xion-ip-to-server-mapping.arn
        ]
      },
    ]
  })
}

resource "aws_iam_instance_profile" "siec" {
  name = "${var.namespace}-${var.stage}-siec-scraper-instance-profile"
  role = aws_iam_role.siec.name
}

locals {
  user_data_params = {}
}

resource "aws_instance" "siec" {
  ami                  = var.siec_scraper_ami_id
  instance_type        = var.siec_scraper_instance_type
  iam_instance_profile = aws_iam_instance_profile.siec.name
  key_name             = "dboesswetter"
  subnet_id            = module.dynamic_subnets.public_subnet_ids[0]

  user_data              = templatefile("userdata.sh", local.user_data_params)
  vpc_security_group_ids = [aws_security_group.ec2.id]
  tags = {
    Name = "${var.namespace}-${var.stage}-siec-scraoer"
  }
}

resource "aws_security_group" "ec2" {
  name        = "${var.namespace}-${var.stage}-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}