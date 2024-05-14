terraform {
  required_version = "1.7.2"
  required_providers {
    aws={
        source = "hashicorp/aws"
        version = "4.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
  profile = "default"
}
resource "aws_vpc" "demo_vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name="Demo VPC"
    }
  
}
resource "aws_internet_gateway" "demo_igw" {
    vpc_id = aws_vpc.demo_vpc.id
}
resource "aws_subnet" "demo_public_subnet" {
    vpc_id = aws_vpc.demo_vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-1a"
    tags = {
      Name="Demo Public Subnet"
    }
}
resource "aws_route_table" "demo_public_rt" {
  vpc_id = aws_vpc.demo_vpc.id
  route  {
    cidr_block="0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_igw.id
    }
    tags = {
            Name = "Demo Public Route Table"
            
    }     
}

resource "aws_route_table_association" "demo_public_rta" {
    subnet_id = aws_subnet.demo_public_subnet.id
    route_table_id = aws_route_table.demo_public_rt.id
}
resource "aws_security_group" "demo" {
    name = "Anand Security Group"
    vpc_id = aws_vpc.demo_vpc.id
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
        description = "Allow HTTP traffic"
    }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allow SSH traffic"
  }
  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allow all outbound traffic"
  }
  tags = {
    Name= "Demo Security Group"
  }
}
resource "aws_instance" "demo_ec2" {
    ami = "ami-0277155c3f0ab2930"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.demo.id]
    associate_public_ip_address = true
    tags = {
      Name="Demo Web Server"
    }
    subnet_id = aws_subnet.demo_public_subnet.id
    user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y httpd
    sudo systemctl start httpd
    sudo systemctl enable httpd
    echo "<h1>Hello from Terraform</h1>" | sudo tee /var/www/html/index.html
    EOF
}