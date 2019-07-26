data "terraform_remote_state" "proyecto1" {
  backend = "s3"
  config = {
    bucket = "jcla"
    key    = "terraform/proyecto1.tfstate"
    region = "us-east-1"
  }
}