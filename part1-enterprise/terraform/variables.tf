variable "subscription_id" {
  description = "Personal Azure subscription (Rishi-PAYG)"
  type        = string
}

variable "location" {
  description = "Azure region for everything"
  type        = string
  default     = "canadacentral"
}

variable "my_ip" {
  description = "My home public IP. Only this IP can RDP in"
  type        = string

  validation {
    condition = can(regex("^\\d{1,3}(\\.\\d{1,3}){3}$", var.my_ip))
    error_message = "my_ip must be an IPv4 address. USE: curl -4 ifconfig.me"
  }
}