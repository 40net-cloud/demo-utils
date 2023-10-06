##############################################################################################################
#
# Workshop student environment
#
##############################################################################################################

##############################################################################################################
# Resource Group
##############################################################################################################

resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.PREFIX}-student${count.index}-RG"
  location = var.LOCATION
  count    = var.ACCOUNTCOUNT

  lifecycle {
    ignore_changes = [tags]
  }

}

resource "azuread_user" "users" {
  user_principal_name = "${var.PREFIX}-student${count.index}@${var.CUSTOMDOMAIN}"
  display_name        = "${var.PREFIX}-student${count.index}"
  mail_nickname       = "${var.PREFIX}-student${count.index}"
  password            = "StudentPassword123!"
  count               = var.ACCOUNTCOUNT
}

resource "azurerm_role_assignment" "iam" {
  scope                = azurerm_resource_group.resourcegroup[count.index].id
  role_definition_name = "Owner"
  principal_id         = azuread_user.users[count.index].id
  count                = var.ACCOUNTCOUNT
}

#resource "azurerm_role_assignment" "iam2" {
#  scope                = "/subscriptions/590be515-152e-431c-b10e-5e98bc348a5a/resourceGroups/JVH10-HA-RG"
#  role_definition_name = "Reader"
#  principal_id         = azuread_user.users[count.index].id
#  count                = var.ACCOUNTCOUNT
#}
#
#resource "azurerm_role_assignment" "iam3" {
#  scope                = "/subscriptions/590be515-152e-431c-b10e-5e98bc348a5a/resourceGroups/JVH10-VM-RG"
#  role_definition_name = "Reader"
#  principal_id         = azuread_user.users[count.index].id
#  count                = var.ACCOUNTCOUNT
#}
#
#resource "azurerm_role_assignment" "iam4" {
#  scope                = "/subscriptions/590be515-152e-431c-b10e-5e98bc348a5a/resourceGroups/JVH10-HA-RG"
#  role_definition_name = "EMEATrainingDEMO"
#  principal_id         = azuread_user.users[count.index].id
#  count                = var.ACCOUNTCOUNT
#}
#
#resource "azurerm_role_assignment" "iam5" {
#  scope                = "/subscriptions/590be515-152e-431c-b10e-5e98bc348a5a/resourceGroups/JVH10-VM-RG"
#  role_definition_name = "EMEATrainingDEMO"
#  principal_id         = azuread_user.users[count.index].id
#  count                = var.ACCOUNTCOUNT
#}

##############################################################################################################
# Azure Policy
##############################################################################################################

resource "azurerm_policy_definition" "limitlocation" {
  name         = "EMEA Training Limit Location"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "EMEA Training Limit Location"

  policy_rule = <<POLICY_RULE
  {
    "if": {
      "not": {
        "field": "location",
        "in": "[parameters('allowedLocations')]"
      }
    },
    "then": {
      "effect": "audit"
    }
  }
POLICY_RULE


  parameters = <<PARAMETERS
  {
    "allowedLocations": {
      "type": "Array",
      "metadata": {
        "description": "The list of allowed locations for resources.",
        "displayName": "Allowed locations",
        "strongType": "location"
      }
    }
  }
PARAMETERS

}

resource "azurerm_resource_group_policy_assignment" "limitlocation2rg" {
  count                = var.ACCOUNTCOUNT
  name                 = "EMEA Training Limit Location ${var.PREFIX}-student${count.index}"
  resource_group_id    = azurerm_resource_group.resourcegroup[count.index].id
  policy_definition_id = azurerm_policy_definition.limitlocation.id
  description          = "EMEA Training Limit Location ${var.PREFIX}-student${count.index}"
  display_name         = "EMEA Training Limit Location ${var.PREFIX}-student${count.index}"

  parameters = <<PARAMETERS
{
  "allowedLocations": {
    "value": [ "${var.LOCATION}" ]
  }
}
PARAMETERS

}

resource "azurerm_policy_definition" "limitinstancesize" {
  name         = "EMEA Training Limit Instance Size"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "EMEA Training Limit Instance Size"

  policy_rule = <<POLICY_RULE
  {
    "if": {
      "allOf": [
          {
          "field": "type",
          "equals": "Microsoft.Compute/virtualMachines"
          },
          {
          "not":
              {
              "field": "Microsoft.Compute/virtualMachines/sku.name",
              "in": "[parameters('allowedInstanceSizes')]"
              }
          }
      ]
    },
    "then": {
      "effect": "deny"
    }
  }
POLICY_RULE


  parameters = <<PARAMETERS
  {
    "allowedInstanceSizes": {
      "type": "Array",
      "metadata": {
        "description": "The list of allowed Instance Sizes for resources.",
        "displayName": "Allowed Instance Sizes",
        "strongType": "allowedinstancesizes"
      }
    }
  }
PARAMETERS

}

resource "azurerm_resource_group_policy_assignment" "limitinstancesize2rg" {
  count                = var.ACCOUNTCOUNT
  name                 = "EMEA Training Limit Instance Size student${count.index}"
  resource_group_id    = azurerm_resource_group.resourcegroup[count.index].id
  policy_definition_id = azurerm_policy_definition.limitinstancesize.id
  description          = "EMEA Training Limit Instance Size student${count.index}"
  display_name         = "EMEA Training Limit Instance Size student${count.index}"

  parameters = <<PARAMETERS
{
  "allowedInstanceSizes": {
    "value": [ 
      "Standard_F2s", "Standard_F4s", "Standard_F8s", "Standard_F2s_v2", 
      "Standard_F4s_v2", "Standard_F8s_v2", "Standard_DS2_v2", "Standard_DS3_v2", "Standard_DS4_v2", 
      "Standard_D2s_v3", "Standard_D4s_v3", "Standard_D8s_v3", 
      "Standard_D2s_v4", "Standard_D4s_v4", "Standard_D8s_v4", 
      "Standard_D2a_v4", "Standard_D4a_v4", "Standard_D8a_v4", 
      "Standard_D2as_v4", "Standard_D4as_v4", "Standard_D8as_v4", 
      "Standard_D2s_v5", "Standard_D4s_v5", "Standard_D8s_v5",
      "Standard_D2as_v5", "Standard_D4as_v5", "Standard_D8as_v5",
      "Standard_D2ads_v5", "Standard_D4ads_v5", "Standard_D8ads_v5",
      "Standard_B1s","Standard_B1ms","Standard_B2s","Standard_B2ms","Standard_B4ms" 
    ]
  }
}
PARAMETERS

}

resource "azurerm_policy_definition" "limitvmimages" {
  name         = "EMEA Training Limit VM Images"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "EMEA Training Limit VM Images"

  policy_rule = <<POLICY_RULE
  {
    "if": {
      "allOf": [
        {
          "field": "type",
          "in": [
            "Microsoft.Compute/virtualMachines",
            "Microsoft.Compute/VirtualMachineScaleSets"
          ]
        },
        {
          "not": {
            "allOf": [
              {
                "field": "Microsoft.Compute/imagePublisher",
                "in": "[parameters('allowedImagePublisher')]"
              },
              {
                "field": "Microsoft.Compute/imageOffer",
                "in": "[parameters('allowedImageOffer')]"
              },
              {
                "field": "Microsoft.Compute/imageSku",
                "in": "[parameters('allowedImageSku')]"
              }
            ]
          }
        }
      ]
    },
    "then": {
      "effect": "deny"
    }
  }
POLICY_RULE

  parameters = <<PARAMETERS
  {
    "allowedImageSku": {
      "type": "Array",
      "metadata": {
        "displayName": "Allowed Image SKU",
        "description": "Allowed Image SKU for Virtual Machine/Compute"
      }
    },
    "allowedImageOffer": {
      "type": "Array",
      "metadata": {
        "displayName": "Allowed Image Offer",
        "description": "Allowed Image Offer Virtual Machine/Compute"
      }
    },
    "allowedImagePublisher": {
      "type": "Array",
      "metadata": {
        "displayName": "Allowed Image Publisher",
        "description": "Allowed Image Publisher Virtual Machine/Compute"
      }
    }
  }
PARAMETERS

}

resource "azurerm_resource_group_policy_assignment" "limitvmimages2rg" {
  count                = var.ACCOUNTCOUNT
  name                 = "EMEA Training Limit VM Images student${count.index}"
  resource_group_id    = azurerm_resource_group.resourcegroup[count.index].id
  policy_definition_id = azurerm_policy_definition.limitvmimages.id
  description          = "EMEA Training Limit VM Images student${count.index}"
  display_name         = "EMEA Training Limit VM Images student${count.index}"

  parameters = <<PARAMETERS
{
  "allowedImageSku": { "value": [ "fortinet_fg-vm", "fortinet_fg-vm_payg_20190624", "fortinet_fg-vm_payg_2022", "fortinet_fg-vm_payg_2023", "18.04-LTS", "20_04-lts", "22_04-lts", "22_04-lts-gen2", "20_04-lts-gen2", "18_04-lts-gen2" ] },
  "allowedImageOffer": { "value": [ "fortinet_fortigate-vm_v5", "UbuntuServer", "0001-com-ubuntu-server-focal", "0001-com-ubuntu-server-jammy" ] },
  "allowedImagePublisher": { "value": [ "fortinet", "Canonical" ] }
}
PARAMETERS

}

#resource "azurerm_policy_set_definition" "example" {
#  name         = "testPolicySet"
#  policy_type  = "Custom"
#  display_name = "Test Policy Set"
#
#  parameters = <<PARAMETERS
#    {
#        "allowedLocations": {
#            "type": "Array",
#            "metadata": {
#                "description": "The list of allowed locations for resources.",
#                "displayName": "Allowed locations",
#                "strongType": "location"
#            }
#        },
#        "allowedImageSku": {
#          "type": "Array",
#          "metadata": {
#            "displayName": "Allowed Image SKU",
#            "description": "Allowed Image SKU for Virtual Machine/Compute"
#          }
#        },
#        "allowedImageOffer": {
#          "type": "Array",
#          "metadata": {
#            "displayName": "Allowed Image Offer",
#            "description": "Allowed Image Offer Virtual Machine/Compute"
#          }
#        },
#        "allowedImagePublisher": {
##          "type": "Array",
#          "metadata": {
#            "displayName": "Allowed Image Publisher",
#            "description": "Allowed Image Publisher Virtual Machine/Compute"
#          }
#        }
#      }
#PARAMETERS
#
#  policy_definition_reference {
#    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988"
#    parameter_values     = <<VALUE
#    {
#      "listOfAllowedLocations": {"value": "[parameters('allowedLocations')]"}
#    }
#    VALUE
#  }
#}
