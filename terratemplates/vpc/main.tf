# data "aws_availability_zones" "azs" {}

resource "aws_vpc" "nwvpc" {
  provider             = aws.NETWORK
  cidr_block           = "${var.nwvpc_cidr}"
  enable_dns_hostnames = "true"

  tags = {
    Name = "NW-newvpc"
  }
}

# Define Internet Gateway

resource "aws_internet_gateway" "igw" {
  provider = aws.NETWORK
  vpc_id   = "${aws_vpc.nwvpc.id}"
  tags = {
    Name = "NWvpc IGW"
  }
}

# Define Elastic IP for NAT 

resource "aws_eip" "nateip" {
  provider = aws.NETWORK
  vpc      = true
}

# Define NAT Gateway

resource "aws_nat_gateway" "ngw" {
  provider = aws.NETWORK

  allocation_id = aws_eip.nateip.id
  subnet_id     = "${aws_subnet.public-subnets.*.id[0]}"
  depends_on    = ["aws_internet_gateway.igw"]

  tags = {
    Name = "NWvpc NGW"
  }
}

# Define Transit Gateway

resource "aws_ec2_transit_gateway" "tgw" {
  provider = aws.NETWORK

  description                    = "UAT Transit Gateway"
  amazon_side_asn                = 64512
  auto_accept_shared_attachments = "enable"
  dns_support                    = "enable"
  vpn_ecmp_support               = "enable"

  tags = {
    Name = "TGW-UAT"
  }
}

# Define RAM Resource share

resource "aws_ram_resource_share" "main" {
  provider = aws.NETWORK

  name                      = "Transit-share"
  allow_external_principals = true
}

resource "aws_ram_principal_association" "example" {
  principal          = "146776836293"
  resource_share_arn = aws_ram_resource_share.main.arn
}

resource "aws_ram_resource_association" "transit_association" {
  provider = aws.NETWORK

  resource_arn       = "${aws_ec2_transit_gateway.tgw.arn}"
  resource_share_arn = "${aws_ram_resource_share.main.id}"
}

# Define Transit Gateway NETWORK Attachment

resource "aws_ec2_transit_gateway_vpc_attachment" "nwvpcattachment" {
  subnet_ids         = [
        "${aws_subnet.nwprivate-subnets.*.id[0]}",
        "${aws_subnet.nwprivate-subnets.*.id[1]}",
        "${aws_subnet.nwprivate-subnets.*.id[2]}",
    ]
  transit_gateway_id = "${aws_ec2_transit_gateway.tgw.id}"
  vpc_id             = "${aws_vpc.nwvpc.id}"

  tags = {
    Name = "NW-new-Attachment"
  }
}

# Define Transit Gateway Attachment

resource "aws_ec2_transit_gateway_vpc_attachment" "uatvpcattachment" {
  provider           = aws.UAT
  subnet_ids         = [
        "${aws_subnet.uatprivate-subnets.*.id[0]}",
        "${aws_subnet.uatprivate-subnets.*.id[1]}",
        "${aws_subnet.uatprivate-subnets.*.id[2]}",
    ]
  transit_gateway_id = "${aws_ec2_transit_gateway.tgw.id}"
  vpc_id             = "${aws_vpc.uatvpc.id}"

  tags = {
    Name = "UAT-new-attach"
  }
}

# Creating Transit Gateway route

resource "aws_ec2_transit_gateway_route" "mainroute" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.nwvpcattachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw.association_default_route_table_id
}

# Define the public subnets for NETOWRK account

resource "aws_subnet" "public-subnets" {
  provider                = aws.NETWORK
  vpc_id                  = "${aws_vpc.nwvpc.id}"
  cidr_block              = "${var.public_cidrs[count.index]}"
  availability_zone       = "${data.aws_availability_zones.azs.names[count.index]}"
  count                   = 2
  map_public_ip_on_launch = true

  tags = {
    Name = "publicsubnet-${count.index + 1}"
  }
}

# Define the private subnets for NETWORK account

resource "aws_subnet" "nwprivate-subnets" {
  provider          = aws.NETWORK
  vpc_id            = "${aws_vpc.nwvpc.id}"
  availability_zone = "${element(data.aws_availability_zones.azs.names, count.index)}"
  cidr_block        = "${element(var.nwprivate_cidrs, count.index)}"
  count             = "${length(data.aws_availability_zones.azs.names)}"

  tags = {
    Name = "privatesubnet-${count.index + 1}"
  }
}

# Define public route table

resource "aws_route_table" "public-subnet-rt" {
  provider = aws.NETWORK

  vpc_id = "${aws_vpc.nwvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
  route {
    cidr_block = "${var.uatvpc_cidr}"
    gateway_id = "${aws_ec2_transit_gateway.tgw.id}"
  }

  tags = {
    Name = "public subnet route"
  }
}

# Define Private route table

resource "aws_route_table" "private-subnet-rt" {
  provider = aws.NETWORK
  vpc_id   = "${aws_vpc.nwvpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.ngw.id}"
  }
  route {
    cidr_block = "${var.uatvpc_cidr}"
    gateway_id = "${aws_ec2_transit_gateway.tgw.id}"
  }

  tags = {
    Name = "private subnet route"
  }
}

resource "aws_default_route_table" "private-subnet-rt" {
  provider               = aws.NETWORK
  default_route_table_id = "${aws_vpc.nwvpc.default_route_table_id}"

  tags = {
    Name = "default route"
  }
}

# Associating route table to public subnet

resource "aws_route_table_association" "public_assoc" {
  provider       = aws.NETWORK
  count          = 2
  subnet_id      = "${aws_subnet.public-subnets.*.id[count.index]}"
  route_table_id = "${aws_route_table.public-subnet-rt.id}"
}

# Associating route table to private subnet

resource "aws_route_table_association" "private_assoc" {
  provider       = aws.NETWORK
  count          = "${length(data.aws_availability_zones.azs.names)}"
  subnet_id      = "${aws_subnet.nwprivate-subnets.*.id[count.index]}"
  route_table_id = "${aws_route_table.private-subnet-rt.id}"
}



# Defining resources for UAT account

resource "aws_vpc" "uatvpc" {
  provider             = aws.UAT
  cidr_block           = "${var.uatvpc_cidr}"
  enable_dns_hostnames = "true"

  tags = {
    Name = "UATnewvpc"
  }
}

# Defining UAT account private subnets

resource "aws_subnet" "uatprivate-subnets" {
  provider          = aws.UAT
  vpc_id            = "${aws_vpc.uatvpc.id}"
  availability_zone = "${element(data.aws_availability_zones.azs.names, count.index)}"
  cidr_block        = "${element(var.uatprivate_cidrs, count.index)}"
  count             = "${length(data.aws_availability_zones.azs.names)}"

  tags = {
    Name  = "NEW-privatesubnet-${count.index + 1}"
  }
}

# Private route table for UAT account

resource "aws_route_table" "uatprivate-subnet-rt" {
  provider = aws.UAT
  vpc_id   = "${aws_vpc.uatvpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_ec2_transit_gateway.tgw.id}"
  }
  tags = {
    Name = "NEW private subnet route"
  }
}

# Associating route table to UAT private subnets

resource "aws_route_table_association" "uatprivate_assoc" {
  provider       = aws.UAT
  count          = "${length(data.aws_availability_zones.azs.names)}"
  subnet_id      = "${aws_subnet.uatprivate-subnets.*.id[count.index]}"
  route_table_id = "${aws_route_table.uatprivate-subnet-rt.id}"
}

