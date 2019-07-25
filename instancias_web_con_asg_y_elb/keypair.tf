resource "aws_key_pair" "jcla_dell" {
  key_name   = "terraform-test-keypair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDRwS/0sAAs6VrJ+Kd4iv2HJ96Cqrm1omibyrDipycJWz/HD5feVw8cUqYX6vX6ReHt8BYhERVnSc/Jsf54FEOKUY9Z+zw3zWXsLAfcAewdaueof9+HbhqIilhOeKRhJ27LPlsdHvCODlP9FIq4kC1F/OvEvSpfXt0Ssu+PEUeyKFT3UGrmRoJeS9+TR/BQnL+1+ywt+Ifvm5SzeKDpw6AuhKGQoOJh4g7C5OYRgm0I2HnSAHOtq2S8g4kwZ7kiWEWVt7/PFdcR6URnNqKhSPrASPJY040oIxrCZ0IjtpP0cr6n9Owm2M4Iu/PceQVkjRGx0B8SxJs8/2CtOAFFCTmF jcla@kubuntu"
}