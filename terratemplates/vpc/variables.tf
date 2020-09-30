variable "uatvpc_cidr" {}
variable "nwvpc_cidr" {}

variable "public_cidrs" {
  type = "list"
}

variable "nwprivate_cidrs" {
  type = "list"
}

variable "uatprivate_cidrs" {
  type = "list"
}

#variable "accessip" {}

data "aws_availability_zones" "azs" {}

