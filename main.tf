terraform {
  required_version = "1.9.8"
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
    name = "new Security Group"
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
    ami = "ami-0866a3c8686eaeeba"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.demo.id]
    associate_public_ip_address = true
    tags = {
      Name="Demo Web Server"
    }
    subnet_id = aws_subnet.demo_public_subnet.id
    user_data = <<-EOF
    #!/bin/sh
    sudo apt-get upgrade -y
    sudo apt-get update -y
    sudo apt-get install apache2 -y
    sudo systemctl start apache2
    sudo apt-get install unzip
    cd /var/www/html/
    wget https://www.tooplate.com/zip-templates/2136_kool_form_pack.zip
    unzip 2136_kool_form_pack.zip
    rm -rf  index.html
    rm -rf 2136_kool_form_pack.zip
    mv 2136_kool_form_pack 1
    EOF
}
