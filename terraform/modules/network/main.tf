### VPC

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name  = "${var.project}-${var.env}-vpc"
    Group = "${var.project}"
  }
}

### Public

resource "aws_subnet" "subnet-public-a" {
  availability_zone       = "${var.region}a"
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.cidr_public_a
  map_public_ip_on_launch = true

  tags = {
    Name  = "${var.project}-${var.env}-subnet-public-a"
    Group = "${var.project}"

    # EKS-specific
    "kubernetes.io/cluster/${var.project}-${var.env}-cluster" = "shared"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "subnet-public-b" {
  availability_zone       = "${var.region}b"
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.cidr_public_b
  map_public_ip_on_launch = true

  tags = {
    Name  = "${var.project}-${var.env}-subnet-public-b"
    Group = "${var.project}"

    # EKS-specific
    "kubernetes.io/cluster/${var.project}-${var.env}-cluster" = "shared"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_route_table" "route-public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = var.cidr_vpc
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id
  }

  tags = {
    Name  = "${var.project}-${var.env}-route-public"
    Group = "${var.project}"
  }
}

resource "aws_route_table_association" "route-public-a" {
  subnet_id      = aws_subnet.subnet-public-a.id
  route_table_id = aws_route_table.route-public.id
}

resource "aws_route_table_association" "route-public-b" {
  subnet_id      = aws_subnet.subnet-public-b.id
  route_table_id = aws_route_table.route-public.id
}

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name  = "${var.project}-${var.env}-internet-gateway"
    Group = "${var.project}"
  }
}

resource "aws_network_acl" "public-acl" {
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = [aws_subnet.subnet-public-a.id, aws_subnet.subnet-public-b.id]

  egress {
    protocol   = "-1"
    rule_no    = 999
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 101
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 102
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "icmp"
    rule_no    = 998
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    icmp_code  = -1
    icmp_type  = -1
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 999
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name  = "${var.project}-${var.env}-public-acl"
    Group = "${var.project}"
  }
}

### Private

resource "aws_subnet" "subnet-private-a" {
  availability_zone = "${var.region}a"
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.cidr_private_a

  tags = {
    Name  = "${var.project}-${var.env}-subnet-private-a"
    Group = "${var.project}"

    # EKS-specific
    "kubernetes.io/cluster/${var.project}-${var.env}-cluster" = "shared"
  }
}

resource "aws_subnet" "subnet-private-b" {
  availability_zone = "${var.region}b"
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.cidr_private_b

  tags = {
    Name  = "${var.project}-${var.env}-subnet-private-b"
    Group = "${var.project}"

    # EKS-specific
    "kubernetes.io/cluster/${var.project}-${var.env}-cluster" = "shared"
  }
}

resource "aws_default_route_table" "route-private" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id

  route {
    cidr_block = var.cidr_vpc
    gateway_id = "local"
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gateway.id
  }

  tags = {
    Name  = "${var.project}-${var.env}-route-private"
    Group = "${var.project}"
  }
}

resource "aws_route_table_association" "route-private-a" {
  subnet_id      = aws_subnet.subnet-private-a.id
  route_table_id = aws_default_route_table.route-private.id
}

resource "aws_route_table_association" "route-private-b" {
  subnet_id      = aws_subnet.subnet-private-b.id
  route_table_id = aws_default_route_table.route-private.id
}

resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.subnet-public-a.id

  tags = {
    Name  = "${var.project}-${var.env}-nat-gateway"
    Group = "${var.project}"
  }
}

resource "aws_eip" "eip" {
  domain = "vpc"

  tags = {
    Name  = "${var.project}-${var.env}-eip"
    Group = "${var.project}"
  }
}

resource "aws_network_acl" "private-acl" {
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = [aws_subnet.subnet-private-a.id, aws_subnet.subnet-private-b.id]

  egress {
    protocol   = "-1"
    rule_no    = 999
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.cidr_vpc
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 101
    action     = "allow"
    cidr_block = var.cidr_vpc
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 102
    action     = "allow"
    cidr_block = var.cidr_vpc
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "icmp"
    rule_no    = 998
    action     = "allow"
    cidr_block = var.cidr_vpc
    icmp_code  = -1
    icmp_type  = -1
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 999
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name  = "${var.project}-${var.env}-private-acl"
    Group = "${var.project}"
  }
}
