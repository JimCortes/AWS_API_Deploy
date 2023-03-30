resource "aws_vpc" "vpc_api" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "vpc_api"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_api.id
  tags = {
    Name = "igw"
  }
}

resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet[0].id
  depends_on    = [aws_internet_gateway.igw]
  tags = {
    Name        = "nat"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc_api.id
  count                   = length(var.public_subnets_cidr)
  cidr_block              = element(var.public_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zone, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name        = "public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc_api.id
  count                   = length(var.private_subnets_cidr)
  cidr_block              = element(var.private_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zone, count.index)
  tags = {
    Name        = "private-subnet-${count.index}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "private-route-table"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "public-route-table"
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "private_nat_gateway" {
  count                  = length(aws_subnet.private_subnet)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public_subnet)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private_subnet)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_security_group" "default" {
  name        = "default-sg"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = aws_vpc.vpc_api.id
  depends_on  = [aws_vpc.vpc_api]
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}