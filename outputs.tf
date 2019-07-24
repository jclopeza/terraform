output "instance_public_ip" {
  value = "${aws_eip.web_eip.public_ip}"
}
output "instance_public_dns" {
  value = "${aws_eip.web_eip.public_dns}"
}