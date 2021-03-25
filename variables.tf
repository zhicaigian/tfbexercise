variable "rgName" {
  type        = string
  description = "The resource group name"
  #   default     = "myTFResourceGroup"
}

variable "rgLocation" {
  type        = string
  description = "The resource group location."
  #   default     = "southeastasia"
}

variable "tags" {
  type = map(string)

  #   default = {
  #     environment = "Terraform Getting Started"
  #     team        = "DevOps"
  #   }
}

variable "admin_username" {
  type        = string
  sensitive   = true
  description = "Username for the VM"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Password for the VM"
}