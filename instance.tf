resource "aws_instance" "web" {
  ami           = "ami-026c8acd92718196b"
  instance_type = "t3.micro"

  tags = {
    Name = "test-terraform"
  }
}