variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "ecs_amis" {
  type = map(string)
  default = {
    us-east-1 = "ami-1924770e"
    us-west-2 = "ami-56ed4936"
    eu-west-1 = "ami-c8337dbb"
  }
}

variable "ecs_Instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  description = "SSH key name to access the EC2 instances"
  default     = "jen_key"
}

variable "vpc_cidr_block" {
  description = "VPC network"
  default     = "10.10.0.0/16"
}

variable "public1_subnet_cidr_block" {
  description = "Public Subnet"
  default     = "10.10.1.0/24"
}

variable "public2_subnet_cidr_block" {
  description = "Public Subnet"
  default     = "10.10.2.0/24"
}

variable "private1_subnet_cidr_block" {
  description = "Private Subnet"
  default     = "10.10.3.0/24"
}

variable "private2_subnet_cidr_block" {
  description = "Private Subnet"
  default     = "10.10.4.0/24"
}

variable "availability_zones" {
  description = "Availability Zones"
  default     = "us-east-1a,us-east-1b,us-east-1c,us-east-1d"
}

variable "autoscale_min" {
    default = "1"
    description = "Minimum autoscale (number of EC2)"
}

variable "autoscale_max" {
    default = "10"
    description = "Maximum autoscale (number of EC2)"
}

variable "autoscale_desired" {
    default = "2"
    description = "Desired autoscale (number of EC2)"
}

