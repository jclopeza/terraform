terraform {
  backend "s3" {
    bucket = "jcla"
    key = "terraform/proyecto2.tfstate"
    region = "us-east-1"
  }
}