data "template_file" "user-data" {
  template = "${file("user-data.txt")}"
  vars = {
      project_name = "${var.project_name}"
  }
}