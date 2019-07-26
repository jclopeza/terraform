module "ec2" {
    // Incluyo la URL del repositorio Git
    source = "github.com/jclopeza/terraform-module-ec2-with-eip?ref=v1.0.2"
    // Como el módulo tiene inputs, tenemos que incluirlos ahora
    vpc_id = "vpc-983f84e1"
    project_name = "calculadora"
    environment = "testing"
    ami = "ami-07d0cf3af28718ef8"
    instance_type = "t2.micro"
    key_name = "jcla"
}