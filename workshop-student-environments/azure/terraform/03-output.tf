##############################################################################################################
#
# Terraform configuration
#
##############################################################################################################

#data "template_file" "summary" {
#  template = file("${path.module}/summary.tpl")
#
#  vars = {
#    location = "${var.LOCATION}"
#  }
#}
#
#output "deployment_summary" {
#  value = data.template_file.summary.rendered
#}
