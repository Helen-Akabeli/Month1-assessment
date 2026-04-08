# TechCorp Web Infrastructure Deployment (Month 1 Assessment)

This repository contains the Terraform configuration to deploy a high-availability, secure web application environment on AWS.

## Prerequisites
- [AWS CLI](https://amazon.com) configured with appropriate permissions.
- [Terraform](https://terraform.io) (v1.0+) installed.
- An existing AWS Key Pair (name should be provided in `terraform.tfvars`).

## Project Structure
```text
terraform-assessment/
├── main.tf                 # Core AWS resource definitions
├── variables.tf            # Input variables
├── outputs.tf              # Infrastructure outputs (ALB DNS, Bastion IP)
├── terraform.tfvars.example # Template for user-specific values
├── user_data/
│   ├── web_server_setup.sh # Apache installation script
│   └── db_server_setup.sh  # Postgres installation script
└── evidence/               # Deployment screenshots
Deployment Steps
Initialize Terraform:

terraform init


Configure Variables:
Copy terraform.tfvars.example to terraform.tfvars and fill in your IP address and key pair name.
Plan Deployment:

terraform plan


Apply Configuration:

terraform apply -auto-approve


Verification
Web Access: Use the alb_dns_name output to access the website via a browser.
SSH Access: SSH into the Bastion Host first, then jump to the Web or DB servers.
DB Connection: Run psql -U postgres on the DB server to verify the installation.
Cleanup
To avoid ongoing AWS costs, destroy the resources:

terraform destroy -auto-approve
