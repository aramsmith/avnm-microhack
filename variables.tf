#######################
#   Project 
#######################
variable "project" {
  description = "Project name for reference, it will be used to name the resourcegroups and resources"
  default = "avnmmicrohack"
  }

######################
# Generic VM Vars
######################
variable "admin_username" {
  description = "Please provide admin username"
  default = "AzureAdmin"
  }

variable "admin_password" {
  description = "Please provide Password, must adhere to Azure password complexity"
  type =  string
  sensitive = true
  }

variable "cidr" {
  description = "CIDR /8 range. All VNET's will get an /16"
  type = string
  default = "10.0.0.0/8"
}

######################
# Config
######################
variable "networks" {
  type = list(object({
    region = string
    spoke_count = number
    vmsize = string
    prefix = string
  }))
  default = [ {
    region = "NorthEurope"
    spoke_count = 1
    vmsize = "Standard_B2ms"
    prefix = "hub"
  },
  {
    region = "NorthEurope"
    spoke_count = 3
    vmsize = "Standard_B2ms"
    prefix = "spoke"
  },
  {
    region = "WestEurope"
    spoke_count = 2
    vmsize = "Standard_B2ms"
    prefix = "spoke"

  } ] 
}


locals {
 networks = flatten([
  for network in var.networks : [
    for i in range(1, network.spoke_count + 1) : {
      prefix = network.prefix
      region = network.region
      vmsize = network.vmsize
      spoke_count = i
    }
  ]
 ])
}




