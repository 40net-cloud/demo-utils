##############################################################################################################
#
# Terraform configuration
#
##############################################################################################################

locals {
  vms = [
    for i in range(var.ACCOUNTCOUNT) : {
      name      = azurerm_linux_virtual_machine.lnxavm[i].name
      public_ip = azurerm_public_ip.lnxapip[i].ip_address
      username  = azurerm_linux_virtual_machine.lnxavm[i].admin_username
      password  = azurerm_linux_virtual_machine.lnxavm[i].admin_password
    }
  ]
}

output "vms" {
  value     = local.vms
  sensitive = true
}

output "deployment_summary" {
  value = templatefile("${path.module}/summary.tpl", {
    location = var.LOCATION
    vms      = local.vms
  })
  sensitive = true
}

/* output "student_upns" {
  value = azuread_user.users[*].user_principal_name
}

output "tap_files" {
  value = [for i in range(var.ACCOUNTCOUNT) : "output/tap-${var.PREFIX}-student${i}.txt"]
} */