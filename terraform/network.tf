data "aws_availability_zones" "available" {}

resource "aws_vpc" "metrics_production_vpc" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  tags                 = merge(local.common_tags, { "Name" : "metrics-production-vpc" })
}
resource "aws_subnet" "public_subnets" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.metrics_production_vpc.id
  cidr_block              = "10.20.${10+count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags                    = merge(local.common_tags, { "Name" : "public-subnet-${data.aws_availability_zones.available.names[count.index]}" })
}

resource "aws_subnet" "private_subnets" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.metrics_production_vpc.id
  cidr_block              = "10.20.${20+count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags                    = merge(local.common_tags, { "Name" : "private-subnet-${data.aws_availability_zones.available.names[count.index]}" })
}

resource "aws_internet_gateway" "metrics_production_igw" {
  vpc_id = aws_vpc.metrics_production_vpc.id
}

resource "aws_security_group" "metrics_production_sg" {
  name        = "${terraform.workspace}-metrics-production-sg"
  description = "SSH from the internet, HTTPS inbound, all outbound"
  vpc_id      = aws_vpc.metrics_production_vpc.id

  dynamic ingress {
    iterator = port
    for_each = var.ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { "Name" : "${terraform.workspace}-metrics-production-security-group" })
}
