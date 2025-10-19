# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ai_sandbox_vpc"
  }
}

# --- Subnets ---
# 1. Public Subnet for internet-facing resources
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true # Instances launched here get a public IP

  tags = {
    Name = "ai_sandbox_public_subnet"
  }
}

# 2. Private Subnet for secure resources like model training instances
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b" # Use a different AZ for high availability

  tags = {
    Name = "ai_sandbox_private_subnet"
  }
}

# --- Networking Gateways ---

# 1. Internet Gateway to allow communication with the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ai_sandbox_igw"
  }
}

# 2. Elastic IP for the NAT Gateway (needs a fixed public IP)
resource "aws_eip" "nat" {
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "ai_sandbox_nat_eip"
  }
}

# 3. NAT Gateway to allow private subnets to access the internet
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id # Must live in a public subnet

  tags = {
    Name = "ai_sandbox_nat_gw"
  }
}


# --- Routing ---

# 1. Public Route Table: Directs internet traffic through the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # Represents all internet traffic
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "ai_sandbox_public_rt"
  }
}

# 2. Private Route Table: Directs internet traffic through the NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0" # Represents all internet traffic
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "ai_sandbox_private_rt"
  }
}


# --- Route Table Associations ---

# Link the public route table to the public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Link the private route table to the private subnet
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}