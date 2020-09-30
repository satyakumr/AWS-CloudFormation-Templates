output "nwvpc_id" {
  value = "${aws_vpc.nwvpc.id}"
}
output "uatvpc_id" {
  value = "${aws_vpc.uatvpc.id}"
}
output "public_subnets" {
  value = "${aws_subnet.public-subnets.*.id}"
}
output "nwprivate_subnets" {
  value = "${aws_subnet.nwprivate-subnets.*.id}"
}
output "uatprivate_subnets" {
  value = "${aws_subnet.uatprivate-subnets.*.id}"
}
#output "public_sg" {
#  value = "${aws_security_group.sg-pub.id}"
#}

output "subnet_ips" {
  value = "${aws_subnet.public-subnets.*.cidr_block}"
}

