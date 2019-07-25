resource "aws_autoscaling_group" "web" {
  name                      = "${var.project_name}-web"
  max_size                  = 2
  min_size                  = 0
  desired_capacity          = 0
  health_check_type         = "ELB"
  load_balancers            = ["${aws_elb.web.name}"]
  launch_configuration      = "${aws_launch_configuration.web.name}"
  // Aqui indicamos la subnet
  vpc_zone_identifier       = "${data.aws_subnet_ids.selected.ids}"
  tag {
    key                 = "Name"
    value               = "${var.project_name}-web-asg"
    propagate_at_launch = true // Con esto indicamos que el tag se ponga también en las instancias que se crean
  }
}