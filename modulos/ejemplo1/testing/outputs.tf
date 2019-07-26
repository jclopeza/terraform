output "connection_string" {
    // El valor que vamos a utilizar del módulo está en el outputs del módulo
    value = "ssh ubuntu@${module.ec2.eip}"
}