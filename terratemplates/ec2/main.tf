data "template_file" "user-init" {
  count    = 2
  template = "${file("${path.module}/userdata.tpl")}"

  vars = {
    firewall_subnets = "${element(var.subnet_ips, count.index)}"
  }
}
resource "aws_instance" "tf_server" {
  count                  = "${var.instance_count}"
  ami                    = "ami-0f93b5fd8f220e428"
  instance_type          = "${var.instance_type}"
  subnet_id              = "${element(var.subnets, count.index)}"
  vpc_security_group_ids = "${var.security_group}"
  key_name               = "${var.key_name}"
  user_data              = "${data.template_file.user-init.*.rendered[count.index]}"

  tags = {
    name = "apacheserver"
  }
}
