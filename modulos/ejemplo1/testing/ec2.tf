module "ec2" {
    // Lo mínimo que necesitamos es la ruta donde estoy guardando el módulo
    source = "/home/jcla/Projects/desarrollo/Terraform/modulos/ec2-with-eip"
    // Como el módulo tiene inputs, tenemos que incluirlos ahora
    vpc_id = "vpc-983f84e1"
    project_name = "calculadora"
    environment = "testing"
    ami = "ami-07d0cf3af28718ef8"
    instance_type = "t2.micro"
    key_name = "jcla"
}