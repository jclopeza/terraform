resource "aws_eip" "web_eip" {
  instance = "${aws_instance.web.id}"
}