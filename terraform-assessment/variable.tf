variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}


variable "key_name" {
  description = "Path to your local SSH public key file"
  type        = string
    
}

variable "my_ip" {
  description = "My public IP for SSH access"
  type        = string
  sensitive   = true
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "azs" {
  description = "Availability Zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "web_instance_type" {
  description = "Instance type for web servers"
  type        = string
  default     = "t3.micro"
}

variable "bastion_instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_type" {
  description = "Instance type for database server"
  type        = string
  default     = "t3.small"
}

variable "replace_user_data" {
  description = "This refreshes the user_data everytime it's being changed"
  type        = bool
  default     = true

}

variable "web_user_password" {
  description = "Password for web-user on web servers (used for bastion SSH access)"
  type        = string
  sensitive   = true
}

variable "db_user_password" {
  description = "Password for db-user on DB server (used for bastion SSH access)"
  type        = string
  sensitive   = true
} 