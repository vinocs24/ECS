# Terraform state will be stored in S3
terraform {
  backend "s3" {
    bucket = "terraform-bucket-vino1234"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

# Use AWS Terraform provider
provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "ecs-vpc" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"
  tags = {
    Name = "ecs-vpc"
  }
}

# Public Subnets 1
resource "aws_subnet" "ecs-public-1" {
  vpc_id                  = aws_vpc.ecs-vpc.id
  cidr_block              = var.public1_subnet_cidr_block
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1a"

  tags = {
    Name = "ecs-public-1"
  }
}


#Public Subnets 2
resource "aws_subnet" "ecs-public-2" {
    vpc_id     = aws_vpc.ecs-vpc.id
    cidr_block = var.public2_subnet_cidr_block
    map_public_ip_on_launch = "true"
    availability_zone       = "us-east-1b"

  tags = {
    Name = "ecs-public-2"
  }
}


#Private Subnet 1
resource "aws_subnet" "ecs-private-1" {
    vpc_id     = aws_vpc.ecs-vpc.id
    cidr_block = var.private1_subnet_cidr_block
    map_public_ip_on_launch = "false"
    availability_zone = "us-east-1c"

    tags = {
        Name = "ecs-private-1"
    }
}

#Private Subnet 2
resource "aws_subnet" "ecs-private-2" {
    vpc_id     = aws_vpc.ecs-vpc.id
    cidr_block = var.private2_subnet_cidr_block
    map_public_ip_on_launch = "false"
    availability_zone = "us-east-1d"

    tags = {
        Name = "ecs-private-2"
    }
}

# Internet Gateway
resource "aws_internet_gateway" "ecs-vpc-internet-gateway" {
  vpc_id = aws_vpc.ecs-vpc.id

  tags = {
    Name = "ecs-vpc-internet-gateway"
  }
}

# Route Tables public
resource "aws_route_table" "ecs-vpc-route-table" {
  vpc_id = aws_vpc.ecs-vpc.id

  route {
    cidr_block = "10.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs-vpc-internet-gateway.id
  }

  tags = {
    Name = "ecs-vpc-route-table"
  }
}

resource "aws_route_table_association" "ecs-vpc-route-table-association1" {
  subnet_id      = aws_subnet.ecs-public-1.id
  route_table_id = aws_route_table.ecs-vpc-route-table.id
}

resource "aws_route_table_association" "demo-vpc-route-table-association2" {
  subnet_id      = aws_subnet.ecs-public-2.id
  route_table_id = aws_route_table.ecs-vpc-route-table.id
}

#Network ACL
resource "aws_network_acl" "ecs-vpc-network-acl" {
    vpc_id = aws_vpc.ecs-vpc.id
    subnet_ids = [aws_subnet.ecs-public-1.id, aws_subnet.ecs-public-2.id]

    egress {
        protocol   = "-1"
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 0
        to_port    = 0
    }

    ingress {
        protocol   = "-1"
        rule_no    = 100
        action     = "allow"
        cidr_block = "0.0.0.0/0"
        from_port  = 0
        to_port    = 0
    }

    tags = {
        Name = "ecs-vpc-network-acl"
    }
 
#NAT
resource "aws_eip" "ecs-eip" {
vpc      = true
}
resource "aws_nat_gateway" "ecs-nat-gw" {
allocation_id = aws_eip.ecs-eip.id
subnet_id = aws_subnet.ecs-public-1.id
depends_on = [aws_internet_gateway.ecs-vpc-internet-gateway]
}

# Terraform Training VPC for NAT
resource "aws_route_table" "ecs-private" {
    vpc_id = aws_vpc.ecs-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.ecs-nat-gw.id
    }

    tags = {
        Name = "ecs-private-1"
    }
}

#Route Tables public using NAT
resource "aws_route_table_association" "ecs-private1" {
    subnet_id = aws_subnet.ecs-private-1.id
    route_table_id = aws_route_table.ecs-private.id
}

resource "aws_route_table_association" "ecs-private2" {
    subnet_id = aws_subnet.ecs-private-2.id
    route_table_id = aws_route_table.ecs-private.id
}

#SG
resource "aws_security_group" "ecs-securitygroup" {
  vpc_id      = aws_vpc.ecs-vpc.id
  name        = "ecs"
  description = "security group for ecs"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.myapp-elb-securitygroup.id]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ecs"
  }
}

resource "aws_security_group" "myapp-elb-securitygroup" {
  vpc_id      = aws_vpc.ecs-vpc.id
  name        = "myapp-elb"
  description = "security group for ecs"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "myapp-elb"
  }
}


# ECR  
resource "aws_ecr_repository" "myapp" {
  name = "myapp"
}
  
# cluster
resource "aws_ecs_cluster" "test-cluster" {
  name = "test-cluster"
}

resource "aws_launch_configuration" "ecs-test-launchconfig" {
  name_prefix          = "ecs-launchconfig"
  image_id             = var.ecs_amis[var.aws_region]
  instance_type        = var.ecs_Instance_type
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ecs-ec2-role.id
  security_groups      = [aws_security_group.ecs-securitygroup.id]
  user_data            = "#!/bin/bash\necho 'ECS_CLUSTER=example-cluster' > /etc/ecs/ecs.config\nstart ecs"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs-example-autoscaling" {
  name                 = "ecs-example-autoscaling"
  vpc_zone_identifier  = [aws_subnet.main-public-1.id, aws_subnet.main-public-2.id]
  launch_configuration = aws_launch_configuration.ecs-test-launchconfig.name
  min_size             = 1
  max_size             = 1
  tag {
    key                 = "Name"
    value               = "ecs-ec2-container"
    propagate_at_launch = true
  }
}


# app
data "template_file" "myapp-task-definition-template" {
  template = file("app.json.tpl")
  vars = {
    REPOSITORY_URL = replace(aws_ecr_repository.myapp.repository_url, "https://", "")
  }
}

resource "aws_ecs_task_definition" "myapp-task-definition" {
  family                = "myapp"
  container_definitions = data.template_file.myapp-task-definition-template.rendered
}

resource "aws_elb" "myapp-elb" {
  name = "myapp-elb"

  listener {
    instance_port     = 3000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 30
    target              = "HTTP:3000/"
    interval            = 60
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  subnets         = [aws_subnet.ecs-public-1.id, aws_subnet.ecs-public-2.id]
  security_groups = [aws_security_group.myapp-elb-securitygroup.id]

  tags = {
    Name = "myapp-elb"
  }
}

resource "aws_ecs_service" "myapp-service" {
  name            = "myapp"
  cluster         = aws_ecs_cluster.test-cluster.id
  task_definition = aws_ecs_task_definition.myapp-task-definition.arn
  desired_count   = 1
  iam_role        = aws_iam_role.ecs-service-role.arn
  depends_on      = [aws_iam_policy_attachment.ecs-service-attach1]

  load_balancer {
    elb_name       = aws_elb.myapp-elb.name
    container_name = "myapp"
    container_port = 3000
  }
  lifecycle {
    ignore_changes = [task_definition]
  }
}
