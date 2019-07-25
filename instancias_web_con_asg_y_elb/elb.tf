resource "aws_elb" "web" {
  name                = "${var.project_name}-elb-web"
  subnets             = ["subnet-064ff72a", "subnet-0caf2300", "subnet-4b69d911"]

  security_groups = ["${aws_security_group.allow_http_anywhere.id}"] //No aplicamos el SG ssh

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 2
    target              = "HTTP:80/"
    interval            = 10
  }

  tags = {
    Name = "${var.project_name}-elb-web"
  }
}