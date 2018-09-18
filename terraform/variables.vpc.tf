variable "vpc_cidr" {
  description = "CIDR for the VPC"
  default     = "172.31.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet"
  default     = "172.31.1.0/24"
}
