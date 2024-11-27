variable "aws_access_key" {
  type = string
}
variable "aws_secret_key" {
  type = string
}
variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "cidr_vpc" {
  description = "CIDR block for the VPC"
  default     = "10.1.0.0/16"
}
variable "cidr_subnet" {
  description = "CIDR block for the public subnet"
  default     = "10.1.0.0/24"
}

variable "instance_type" {
  description = "Instance type for the proxy server"
  default = "t3.micro"
}
variable "inbound_ipv4_cidr" {
  description = "CIDR block to allow inbound proxy and SSH traffic"
  # set to home IP address in tfvars
}
variable "proxy_port" {
  type = number
  default = 8888
}
