output "web_public_ip_proyecto1" {
    value = "${data.terraform_remote_state.proyecto1.outputs.web_public_ip}"
}