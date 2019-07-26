output "sg_id" {
    // Devolvemos el id del security group creado.
    value = "${aws_security_group.sg.id}"
}
output "eip" {
    // Devolvemos el id del security group creado.
    value = "${aws_eip.eip.public_ip}"
}