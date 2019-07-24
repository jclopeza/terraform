resource "aws_instance" "web" {
  ami           = "ami-026c8acd92718196b"
  instance_type = "t3.micro"
  key_name = "jcla"
  vpc_security_group_ids = ["${aws_security_group.allow_ssh_anywhere.id}"]

  tags = {
    Name = "test-terraform"
  }
}