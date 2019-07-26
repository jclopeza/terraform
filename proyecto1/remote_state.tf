terraform {
  backend "s3" {
    bucket = "jcla"
    key    = "terraform/proyecto1.tfstate"
    region = "us-east-1"
  }
}