resource "aws_launch_configuration" "web" {
  name_prefix          = "${var.project_name}-lc_" // Más versátil que name
  image_id      = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.instance_type}"
  key_name      = "${aws_key_pair.jcla_dell.key_name}"
  security_groups = [
    "${aws_security_group.allow_ssh_anywhere.id}",
    "${aws_security_group.allow_http_anywhere.id}"
    ]
  user_data = "${data.template_file.user-data.rendered}"
  // Aquí no necesitamos los tags ya que se indican directamente en el autoscaling group
  lifecycle {
      create_before_destroy = true
  }
}
