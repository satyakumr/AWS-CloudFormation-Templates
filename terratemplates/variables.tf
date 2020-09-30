#____ Networking Variables

variable "aws_region" {
  default = "ap-south-1"
}

variable "nwvpc_cidr" {}
variable "uatvpc_cidr" {}

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

#____ Compute Variables

variable "node_ssh_key" {}
variable "instance_type" {}
#variable "public_key_path" {}
#variable "instance_count" {
#  default = 2
#}
