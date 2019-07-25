resource "aws_instance" "web" {
  ami           = "${data.aws_ami.ubuntu.image_id}"
  instance_type = "${var.instance_type}"
  key_name = "${aws_key_pair.jcla_dell.key_name}"
  vpc_security_group_ids = [
      "${aws_security_group.allow_ssh_anywhere.id}",
      "${aws_security_group.allow_http_anywhere.id}"
    ]
  user_data = "${file("user-data.txt")}"
  tags = {
    Name = "${var.project_name}-instance"
  }
}