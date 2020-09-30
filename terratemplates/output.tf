# Networking Outputs

output "Public_Subnets" {
  value = "${join(", ", module.vpc.public_subnets)}"
}

output "nwprivate_Subnets" {
  value = "${join(", ", module.vpc.nwprivate_subnets)}"
}

output "uatprivate_Subnets" {
  value = "${join(", ", module.vpc.uatprivate_subnets)}"
}

output "Subnet_IPs" {
  value = "${join(", ", module.vpc.subnet_ips)}"
}

#output "Public_Security_Group" {
#  value = "${module.vpc.public_sg}"
#}

# Compute Outputs

#output "Public_Instances_IDs" {
#  value = "${module.ec2.server_id}"
#}

#output "Public_Instances_IPs" {
#  value = "${module.ec2.server_ip}"
#}
