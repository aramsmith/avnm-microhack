terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.55.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

module "Networks" {
  count = length(local.networks)
  source = "./network_module"
  project = var.project
  region = local.networks[count.index].region
  cidr = cidrsubnet(var.cidr,8,count.index + 10)
  vmsize = local.networks[count.index].vmsize
  prefix = local.networks[count.index].prefix == "hub" ? local.networks[count.index].prefix : "${local.networks[count.index].prefix}${count.index}"
  admin_password = var.admin_password
  admin_username = var.admin_username
}