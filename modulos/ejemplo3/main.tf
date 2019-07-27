module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "2.9.0" // También podríamos haber puesto source = "terraform-aws-modules/vpc/aws?ref=2.9.0"

  name = "vpc-calculator"
  cidr = "192.168.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
  public_subnets  = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]

  enable_nat_gateway = false // Las redes privadas no tendrán acceso a internet
  enable_vpn_gateway = false

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

module "ec2" {
    source  = "jclopeza/ec2-with-eip/module"
    version = "1.0.3"
    vpc_id = "${module.vpc.vpc_id}"
    project_name = "calculadora"
    environment = "testing"
    ami = "ami-07d0cf3af28718ef8"
    instance_type = "t2.micro"
    key_name = "jcla"
    subnet_id = "${module.vpc.public_subnets[0]}"
}
