locals {
  common_tags = {
    environment = terraform.workspace
    application_name = "metrics_production"
  }
}

variable "ingress_ports" {
  type    = list(number)
  default = [80, 443, 22]
}