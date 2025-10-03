#Configure AWS Provider
#Tells Terraform which cloud and region to use
provider "aws" {
    region = "us-east-1"
}
#Retrieve the list of Availability Zones in the current AWS region
#Gets available AZs and current region for resource placement
data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

#Defining a VPC by creating a Virtual Private Cloud with the CIDR block variables and adding tags for verification
#Creates the private network to host all resources
resource "aws_vpc" "vpc" {
    cidr_block = var.vpc_cidr

    tags = {
        Name        =  var.vpc_name
        Environment = "demo_environment"
        Terraform   = "true"
    }  
}

#Deploy the private subnets by looping multiple private subnets and assigning them to a VPC with separate AZ and tag
#Isolates resources from the internet for security
resource "aws_subnet" "private_subnets" {
    for_each = var.private_subnets
    vpc_id = aws_vpc.vpc_id
    cidr_block = cidrsubnet(var.vpc_cidr, 8, each.value)
    availability_zone = tolist(data.aws_availability_zones.available.names)[each.value]

    tags = {
        Name = each.key
        Terraform = "true"
    }
}

#Deploy the public subnets similar to private subnets but aslo ensures each instance gets a public IP
#Allows resources to communicate directly with the internet
resource "aws_subnet" "public_subnets" {
    for_each = var.public_subnets
    vpc_id = aws_vpc.vpc.id
    cidr_block = cidrsubnet(var.vpc_cidr, 8, each.value + 100)
    availability_zone = tolist(data.aws_availability_zones.available.names)[each.value]
    map_public_ip_on_launch = true

    tags = {
        Name = each.key
        Terraform = "true"
    }
}

#Create route tables for public and private subnets, which routes Public route table to the internet gateway and the private route table to the NAT gateway
#Directs public subnet traffic to the Internet Gateway
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route = {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
    nat_gateway_id = aws_nat_gateway.nat_gateway_id
  }
  tags = {
    Name = "demo_public_rtb"
    Terraform = "true"
  }
}

#Routes private subnet traffic through NAT Gateway
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route = {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
    nat_gateway_id = aws_nat_gateway.nat_gateway_id
  }
  tags = {
    Name = "demo_private_rtb"
    Terraform = "true"
  }
}

#Create route table associations so each subnet is associated with a route table
#Connects subnets to the correct route rules
resource "aws_route_table_association" "public" {
    depends_on = [aws_subnet.public_subnets]
    route_table_id = aws_route_table.public_route_table.id
    for_each = aws_subnet.public_subnets
    subnet_id = each.value.id
}

resource "aws_route_table_association" "private" {
  depends_on = [aws_subnet.private_subnets]
  route_table_id = aws_route_table.private_route_table.id
  for_each = aws_subnet.private_subnets
  subnet_id = each.value.id
}

#Create Internet Gateway so resources in public subnets can reach the internet
#Provides internet access for public subnets
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "demo_igw"
  }
}

#Create EIP for NAT gateway which allocates an Elastic IP for the NAT gateway
#Lets private subnets access the internet securely
resource "aws_eip" "nat_gateway_eip" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.internet_gateway]
  tags = {
    Name = "demo_igw_eip"
  }
}

#Create NAT gateway which allows private subnets to reach the internet outbound only
resource "aws_nat_gateway" "nat_gateway" {
    depends_on = [aws_subnet.public_subnets]
    allocation_id = aws_eip.nat_gateway_eip.id
    subnet_id = aws_subnet.public_subnets["public_subnet_1"].id
    tags = {
        Name = "demo_nat_gateway"
    }
}

#All that is left to do is to setup your AWS credentials variables
#Be sure that the AWS credentials have IAM admininstrative privileges
#WARNING it is not recommended to store your credentials in the AWS provider block

#FINAL STEPS
#1)Configure AWS Credentials  
#Set up AWS credentials with IAM administrative privileges.
#Do not store credentials directly in Terraform files.

#2)Validate Code - Command | Terraform Validate
#Check that your Terraform configuration has no syntax errors.
#Successful validation confirms your code is safe to proceed.

#3)Initialize Terraform - Command | Terraform Init
#Terraform downloads all necessary providers and plugins.
#Initialization ensures Terraform can interact with your cloud environment.

#4)Review the Plan - Command | Terraform Plan
#Terraform compares your code with your current infrastructure.
#You will see a summary of what changes will be made (additions, modifications, deletions).
#Review carefully before proceeding.

#5)Apply Configuration - Command | Terraform Apply - when prompted type yes to proceed
#Approve the changes to create or update your infrastructure.
#Terraform will build resources as defined in your configuration.
#The process may take a few minutes, and completion is confirmed with a success message.

#6)Verify in AWS
#Log in to the AWS Management Console to confirm resources were created correctly.

#7)Destroy Resources (Optional) - Command | Terraform Destroy
#If needed, remove all resources created by Terraform.
#Terraform will prompt for confirmation before deletion.
#Completion is confirmed with a message showing resources were destroyed.

