terraform {
  required_version = ">= 1.14.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}


#==========VPC=========
resource "aws_vpc" "techcorp_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true


  tags = {
    Name = "techcorp-vpc"
  }
}

#=========AWS PUBLIC SUBNETS=========
resource "aws_subnet" "public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.techcorp_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "techcorp-public-subnet-${count.index + 1}"
  }
}


#=========AWS PRIVATE SUBNETS==========
resource "aws_subnet" "private_subnet" {
  count             = 2
  vpc_id            = aws_vpc.techcorp_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "techcorp-private-subnet-${count.index + 1}"
  }
}


#========INTERNET GATEWAY==========
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.techcorp_vpc.id

  tags = {
    Name = "techcorp-igw"
  }
}

#=======ROUTE TABLES==========
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.techcorp_vpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "techcorp-public-rt"
  }
}

#=========ASSOCIATE PUBLIC SUBNETS========= 
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public_subnet)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

#====ELASTIC IP FOR NAT=======
resource "aws_eip" "nat_eip" {
  count  = length(aws_subnet.public_subnet)
  domain = "vpc"

  tags = {
    Name = "techcorp-eip-${count.index + 1}"
  }
}


#=======NAT GATEWAYS=======
resource "aws_nat_gateway" "nat" {
  count         = length(aws_subnet.public_subnet)
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "techcorp-nat-${count.index + 1}"
  }
}

#=====PRIVATE ROUTE TABLES=====
resource "aws_route_table" "private_rt" {
  count  = length(aws_subnet.private_subnet)
  vpc_id = aws_vpc.techcorp_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Name = "techcorp-private-rt-${count.index + 1}"
  }
}

#=====PRIVATE ROUTE ASSOCIATIONS=====
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private_subnet)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}

#=====SECURITY GROUPS======
#=====BASTION-SG======
resource "aws_security_group" "bastion_sg" {
  name   = "techcorp-bastion-sg"
  vpc_id = aws_vpc.techcorp_vpc.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Bastion Host"
  }
}

#===WEB-SG====
resource "aws_security_group" "web_sg" {
  name   = "techcorp-web-sg"
  vpc_id = aws_vpc.techcorp_vpc.id

  ingress {
    description     = "HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web Servers"
  }
}
#====ALB-SG===
resource "aws_security_group" "alb_sg" {
  name   = "techcorp-alb-sg"
  vpc_id = aws_vpc.techcorp_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALB"
  }
}

#===DATABASE-SG===
resource "aws_security_group" "db_sg" {
  name   = "techcorp-db-sg"
  vpc_id = aws_vpc.techcorp_vpc.id

  ingress {
    description     = "Postgres from Web"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Database"
  }
}

#====AMI=======
data "aws_ami" "amazon_linux" {

  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

#====Bastion Host========
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.bastion_instance_type
  subnet_id     = aws_subnet.public_subnet[0].id

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  key_name = var.key_name

  associate_public_ip_address = true

  tags = {
    type = "ssh-bastion"
    Name = "techcorp-bastion"
  }
}

#===BASTION EIP=====
resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = {
    Name = "techcorp-bastion-eip"
  }
}

#=====WEB SERVERS====
resource "aws_instance" "webs" {
  count         = 2
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.web_instance_type
  subnet_id     = aws_subnet.private_subnet[count.index].id

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = base64encode(templatefile("user_data/web_server_setup.sh", {
    web_user_password = var.web_user_password
  }))
  user_data_replace_on_change = var.replace_user_data

  key_name = var.key_name

  tags = {
    type = "web-server"
    Name = "techcorp-web-${count.index + 1}"
  }
}

#===DATABASE SERVER=======
resource "aws_instance" "db" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.db_instance_type
  subnet_id     = aws_subnet.private_subnet[0].id

  vpc_security_group_ids = [aws_security_group.db_sg.id]

  user_data = base64encode(templatefile("user_data/db_server_setup.sh", {
    db_user_password = var.db_user_password
  }))
  user_data_replace_on_change = var.replace_user_data

  key_name = var.key_name

  tags = {
    type = "database-server"
    Name = "techcorp-db"
  }
}

#======APPLICATION LOAD BALANCER=======
resource "aws_lb" "techcorp_alb" {

  name               = "techcorp-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb_sg.id]

  subnets = aws_subnet.public_subnet[*].id

  tags = {
    Name = "techcorp-alb"
  }
}

#===TARGET GROUP====
resource "aws_lb_target_group" "web_tg" {

  name     = "techcorp-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.techcorp_vpc.id

  health_check {

    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "webs" {
  count            = 2
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.webs[count.index].id
  port             = 80
}

resource "aws_lb_listener" "http_listener" {

  load_balancer_arn = aws_lb.techcorp_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {

    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}
