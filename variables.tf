variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "ami-09a9858973b288bdd (must support Node.js installation)"
  type        = string
}

variable "instance_type" {
  description = "t3.medium"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "demo (must be pre-created in AWS)"
  type        = string
}

variable "security_group_id" {
  description = "sg-0d7375fd4c1f55d51 (and HTTP/HTTPS if needed)"
  type        = string
}
