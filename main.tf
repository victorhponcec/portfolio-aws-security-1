provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Project = "Security"
      Name    = "Victor-Ponce"
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.111.0.0/16"
}

#Web Tier
resource "aws_subnet" "public_a_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.111.1.0/24"
  availability_zone = "us-east-1a"
}
resource "aws_subnet" "public_b_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.111.2.0/24"
  availability_zone = "us-east-1b"
}
#App Tier
resource "aws_subnet" "private_a_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.111.3.0/24"
  availability_zone = "us-east-1a"
}
resource "aws_subnet" "private_b_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.111.4.0/24"
  availability_zone = "us-east-1b"
}
#DB Tier
resource "aws_subnet" "private_c_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.111.11.0/24"
  availability_zone = "us-east-1a"
}
resource "aws_subnet" "private_d_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.111.12.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_a_az1.id
  route_table_id = aws_route_table.public_rtb.id
}
resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_b_az2.id
  route_table_id = aws_route_table.public_rtb.id
}

#to do: VPC Endpoints (PrivateLink) for Systems Manager | allow session manager to private subne
#+rtb association