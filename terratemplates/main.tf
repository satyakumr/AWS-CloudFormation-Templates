provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source           = "./vpc"
  nwvpc_cidr       = "${var.nwvpc_cidr}"
  uatvpc_cidr      = "${var.uatvpc_cidr}"
  public_cidrs     = "${var.public_cidrs}"
  nwprivate_cidrs  = "${var.nwprivate_cidrs}"
  uatprivate_cidrs = "${var.uatprivate_cidrs}"
  # accessip         = "${var.accessip}"
}

module "eks" {
  source              = "./eks"
  nodes_ssh_key       = "${var.node_ssh_key}"
  node_instances_type = "${var.instance_type}"
  uatprivate-subnets  = "${module.vpc.uatprivate_subnets}"
  uatvpc              = "${module.vpc.uatvpc_id}"
}

#module "ec2" {
#  source           = "./ec2"
#  instance_count   = "${var.instance_count}"
#  key_name         = "${var.key_name}"
#  public_key_path  = "${var.public_key_path}"
#  instance_type    = "${var.instance_type}"
#  subnets          = "${module.vpc.public_subnets}"
#  security_group   = "${module.vpc.public_sg}"
#  subnet_ips       = "${module.vpc.subnet_ips}"
#}
