terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# 1. Custom Isolated Network (VPC)
resource "aws_vpc" "parish_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "parishos-vpc" }
}

# 2. Public Internet Access Way
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.parish_vpc.id
  tags   = { Name = "parishos-igw" }
}

# 3. Public Routing Topology
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.parish_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true # Automatically assigns a public IP to our instance

  tags = { Name = "parishos-public-subnet" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.parish_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "parishos-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 4. Strict Security Firewall (Security Group)
resource "aws_security_group" "vps_sg" {
  name        = "parishos-ec2-sg"
  description = "Allow inbound SSH and HTTP traffic"
  vpc_id      = aws_vpc.parish_vpc.id

  # SSH Access
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # For high-speed testing this weekend; lock down to your IP later
  }

  # Production Web Traffic
  ingress {
    description = "HTTP application traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Unrestricted Outbound (Necessary for downloading Docker packages/dependencies)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "parishos-security-group" }
}

# 5. Dynamic AMI Lookup for Cost-Effective Graviton (ARM64) Ubuntu Server
data "aws_ami" "ubuntu_arm" {
  most_recent = true
  owners      = ["099720109477"] # Official Canonical Owner ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }
}

# 6. Production Key Pair Configuration
# Generates an SSH key pair locally so you never check sensitive private keys into Git
resource "aws_key_pair" "deployer_key" {
  key_name   = "parishos-deployer-key"
  public_key = file("~/.ssh/id_rsa.pub") # Pulls your machine's local public key
}

# 7. The $4.50/mo Graviton EC2 Engine
resource "aws_instance" "parish_server" {
  ami           = data.aws_ami.ubuntu_arm.id
  instance_type = "t4g.small" # 2 vCPUs, 0.5GB RAM - Blazing fast for native C-level SQLite execution
  
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.vps_sg.id]
  key_name               = aws_key_pair.deployer_key.key_name

  # Automated Zero-Touch Bootstrapping
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io git docker-compose
              systemctl start docker
              systemctl enable docker
              
              # Allow standard ubuntu admin to query Docker without sudo
              usermod -aG docker ubuntu
              
              # Install Docker Compose Plugin natively
              mkdir -p /usr/local/lib/docker/cli-plugins/
              curl -SL https://github.com -o /usr/local/lib/docker/cli-plugins/docker-compose
              chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
              
              # Construct isolated runtime project directory
              mkdir -p /home/ubuntu/parish-os
              chown -R ubuntu:ubuntu /home/ubuntu/parish-os

              # 5. Clone the application repository directly into the workspace
              # Using the dot '.' clones the contents directly inside parish-os instead of creating a subfolder
              git clone https://github.com/yakobos/parish .
              cd parish/shared/architecture

              # 6. Secure workspace permissions back to the standard admin user
              chown -R ubuntu:ubuntu /home/ubuntu/parish-os

              # 7. Start the application container structure instantly
              # Note: This executes your docker-compose config automatically on boot
              docker compose up -d
              EOF

  root_block_device {
    volume_size           = 8 # 8GB SSD is plenty for millions of rows in SQLite; stays under free-tier limits if applicable
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name        = "ParishOS-Production-Core"
    Architecture = "ARM64-Graviton"
  }
}

# Output variables to terminal console upon script completion
output "ec2_public_ip" {
  value       = aws_instance.parish_server.public_ip
  description = "The public IP address to access your production setup via smartphone browser"
}

output "ssh_connection_command" {
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.parish_server.public_ip}"
  description = "Copy-pasteable command to tunnel straight into your EC2 workspace host"
}
