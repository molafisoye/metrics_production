resource "aws_placement_group" "mqtt-autoscaling-placement-group" {
  name     = "mqtt-autoscaling-placement-group"
  strategy = "spread"
}

resource "aws_autoscaling_group" "mqtt-autoscaling-group" {
  name                      = "${terraform.workspace}-mqtt-autoscaling-group"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 1
  force_delete              = true
  placement_group           = aws_placement_group.mqtt-autoscaling-placement-group.id
  launch_configuration      = aws_launch_configuration.mqtt-autoscaling-launch-configuration.name
  vpc_zone_identifier       = [element(aws_subnet.private_subnets.*.id, 1), element(aws_subnet.private_subnets.*.id, 2), element(aws_subnet.private_subnets.*.id, 3)]

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${terraform.workspace}-mqtt-autoscaling-service"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "mqtt-autoscaling-launch-configuration" {
  name_prefix                 = "${terraform.workspace}-instance-launch-conf"
  image_id                    = "ami-51537029"
  instance_type               = "m5.large"
  security_groups             = [aws_security_group.metrics_production_sg.id]
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_elb" "mqtt-autoscaling-elb" {
  name                      = "${terraform.workspace}-mqtt-autoscaling-elb"
  security_groups           = [aws_security_group.metrics_production_sg.id]
  subnets                   = [element(aws_subnet.private_subnets.*.id, 0), element(aws_subnet.private_subnets.*.id, 1), element(aws_subnet.private_subnets.*.id, 2), element(aws_subnet.private_subnets.*.id, 3)]
  cross_zone_load_balancing = true

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    target              = "HTTP:80/"
  }

  listener {
    lb_port           = 80
    lb_protocol       = "TCP"
    instance_port     = "1883"
    instance_protocol = "TCP"
  }

  listener {
    lb_port           = 81 //8443
    lb_protocol       = "TCP" //ssl
    instance_port     = "8080"
    instance_protocol = "TCP"
  }

  listener {
    lb_port           = 82     //443
    lb_protocol       = "TCP" //ssl
    instance_port     = "8083"
    instance_protocol = "TCP"
  }
}


resource "aws_elb" "metrics-elb" {
  name                      = "${terraform.workspace}-elb-metrics-elb"
  security_groups           = [aws_security_group.metrics_production_sg.id]
  subnets                   = [element(aws_subnet.private_subnets.*.id, 0), element(aws_subnet.private_subnets.*.id, 1), element(aws_subnet.private_subnets.*.id, 2), element(aws_subnet.private_subnets.*.id, 3)]
  cross_zone_load_balancing = true
  instances                 = [aws_instance.metrics-instance.id]

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    target              = "HTTP:80/"
  }

  listener {
    lb_port           = 80 //8443
    lb_protocol       = "TCP" //ssl
    instance_port     = "8080"
    instance_protocol = "TCP"
  }

}