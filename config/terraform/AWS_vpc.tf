// Defining the VPC
resource "aws_vpc" "vpc" {
  cidr_block = "192.168.0.0/16"
}


// EKS requires 3 subnets
resource "aws_subnet" "useast2a" {
  availability_zone = "us-east-2a"
  cidr_block        = "192.168.1.0/24"
  vpc_id            = "${aws_vpc.vpc.id}"
}

resource "aws_subnet" "useast2b" {
  availability_zone = "us-east-2b"
  cidr_block        = "192.168.2.0/24"
  vpc_id            = "${aws_vpc.vpc.id}"
}

resource "aws_subnet" "useast2c" {
  availability_zone = "us-east-2c"
  cidr_block        = "192.168.3.0/24"
  vpc_id            = "${aws_vpc.vpc.id}"
}


// Gateway to the internet
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
}


// VPN Gateway to GCP
resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id = "${aws_vpc.main.id}"
  amazon_side_asn = 64512
}

// GCP Customer Gateway
resource "aws_customer_gateway" "cgw" {
  bgp_asn    = 65000
  ip_address = "lorem"
  type       = "ipsec.1"
}

// VPC Connection
resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = "${aws_vpn_gateway.vpn_gw.id}"
  customer_gateway_id = "${aws_customer_gateway.cgw.id}"
  type                = "ipsec.1"
  static_routes_only  = true
}


// Route table
resource "aws_route_table" "poc" {
  vpc_id = "${aws_vpc.vpc.id}"

  // Route to GCP Machines
  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "${aws_vpn_gateway.vpn_gw.id}"
  
  }


  // Route to GCP Pods
  route {
    cidr_block = "10.1.0.0/20"
    gateway_id = "${aws_vpn_gateway.vpn_gw.id}"
  }


  // Route to GCP Services
  route {
    cidr_block = "172.16.0.0/24"
    gateway_id = "${aws_vpn_gateway.vpn_gw.id}"
  }


  // Route to the internet
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
}


// Associates subnets to route table
resource "aws_route_table_association" "poc" {

  subnet_id      = "${aws_subnet.poc.useast2a.id}"
  subnet_id      = "${aws_subnet.poc.useast2b.id}"
  subnet_id      = "${aws_subnet.poc.useast2c.id}"
  route_table_id = "${aws_route_table.poc.id}"
}


// Security group to and from GCP
resource "aws_security_group" "gcp" {
  name        = "gcp"
  description = "Allows traffic between the AWS VPC and the GCP VPC"
  vpc_id      = "${aws_vpc.vpc.id}"

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

// Security Group Rules
resource "aws_security_group_rule" "to_nodes_tcp" {
  cidr_blocks       = ["10.0.0.0/16"]
  description       = "Allows machines to communicate with GCP Nodes on TCP"
  from_port         = 0
  protocol          = "tcp"
  security_group_id = "${aws_security_group.gcp.id}"
  to_port           = 65535
  type              = "ingress"
}

resource "aws_security_group_rule" "to_nodes_udp" {
  cidr_blocks       = ["10.0.0.0/16"]
  description       = "Allows machines to communicate with GCP Nodes on UDP"
  from_port         = 0
  protocol          = "udp"
  security_group_id = "${aws_security_group.gcp.id}"
  to_port           = 65535
  type              = "ingress"
}

resource "aws_security_group_rule" "to_nodes_icmp" {
  cidr_blocks       = ["10.0.0.0/16"]
  description       = "Allows machines to communicate with GCP Nodes on ICMP"
  from_port         = -1
  protocol          = "icmp"
  security_group_id = "${aws_security_group.gcp.id}"
  to_port           = -1
  type              = "ingress"
}

resource "aws_security_group_rule" "to_pods_tcp" {
  cidr_blocks       = ["10.1.0.0/16"]
  description       = "Allows machines to communicate with GCP Pods on TCP"
  from_port         = 0
  protocol          = "tcp"
  security_group_id = "${aws_security_group.gcp.id}"
  to_port           = 65535
  type              = "ingress"
}

resource "aws_security_group_rule" "to_pods_udp" {
  cidr_blocks       = ["10.1.0.0/16"]
  description       = "Allows machines to communicate with GCP Pods on UDP"
  from_port         = 0
  protocol          = "udp"
  security_group_id = "${aws_security_group.gcp.id}"
  to_port           = 65535
  type              = "ingress"
}

resource "aws_security_group_rule" "to_pods_icmp" {
  cidr_blocks       = ["10.1.0.0/16"]
  description       = "Allows machines to communicate with GCP Pods on ICMP"
  from_port         = -1
  protocol          = "icmp"
  security_group_id = "${aws_security_group.gcp.id}"
  to_port           = -1
  type              = "ingress"
}

resource "aws_security_group_rule" "to_pods_sctp" {
  cidr_blocks       = ["10.1.0.0/16"]
  description       = "Allows machines to communicate with GCP Pods on SCTP"
  from_port         = -1
  protocol          = "sctp"
  security_group_id = "${aws_security_group.gcp.id}"
  to_port           = -1
  type              = "ingress"
}

resource "aws_security_group_rule" "to_pods_esp" {
  cidr_blocks       = ["10.1.0.0/16"]
  description       = "Allows machines to communicate with GCP Pods on ESP"
  from_port         = -1
  protocol          = "esp"
  security_group_id = "${aws_security_group.gcp.id}"
  to_port           = -1
  type              = "ingress"
}

resource "aws_security_group_rule" "to_pods_ah" {
  cidr_blocks       = ["10.1.0.0/16"]
  description       = "Allows machines to communicate with GCP Pods on AH"
  from_port         = -1
  protocol          = "ah"
  security_group_id = "${aws_security_group.gcp.id}"
  to_port           = -1
  type              = "ingress"
}