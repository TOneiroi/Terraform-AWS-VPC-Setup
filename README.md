# Terraform-AWS-VPC-Setup
This repository provides Terraform configurations to create a secure AWS VPC environment with public and private subnets, route tables, and internet/NAT gateways. It’s designed for scalable and manageable cloud deployments.

Features
AWS Provider – Configures Terraform to use AWS in us-east-1.

Environment Info – Retrieves available Availability Zones (AZs) and the current region.

VPC – Creates a VPC with a defined CIDR block and tags (Name, Environment, Terraform).

Subnets

  Private: Isolated, distributed across AZs.

  Public: Internet-accessible, assigns public IPs to instances.

Route Tables

  Public: Routes traffic to the Internet Gateway (IGW).

  Private: Routes private subnet traffic through a NAT Gateway.

  Subnets associated with the correct route tables.

Internet & NAT Gateway

  IGW: Provides internet access to public subnets.

  Elastic IP (EIP): Allocated for NAT Gateway.

  NAT Gateway: Enables outbound internet access for private subnets.

Deployment Workflow

  Configure AWS credentials (IAM admin privileges recommended).

  Validate Terraform: terraform validate

  Initialize Terraform: terraform init

  Review execution plan: terraform plan

  Apply configuration: terraform apply

  Verify resources in the AWS Console

  Optionally destroy all resources: terraform destroy
