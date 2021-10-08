locals {
  tags = {
    Region = "us-east-1"
  }
}

resource "aws_instance" "metrics-instance" {
  ami                         = "ami-51537029"
  instance_type               = "m5.large"
  subnet_id                   = element(aws_subnet.private_subnets.*.id, 1)
  vpc_security_group_ids      = [aws_security_group.metrics_production_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 20
    encrypted   = true
  }


  tags = merge(local.tags, { "Name" : "${terraform.workspace}-metrics-production-ec2-instance" })
}


