##############################################################################################################
#
# Workshop student environment
#
##############################################################################################################

variable "PREFIX" {
  description = "Prefix"
}

variable "LOCATION" {
  description = "Azure region"
}

variable "ACCOUNTCOUNT" {
  description = "Number of student accounts to create"
}

variable "CUSTOMDOMAIN" {
  description = "Verified custom domain to use for user accounts"
}

##############################################################################################################
# Minimum terraform version
##############################################################################################################

terraform {
  required_version = ">= 0.12"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.0.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.0.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

}

provider "azuread" {
}

##############################################################################################################
