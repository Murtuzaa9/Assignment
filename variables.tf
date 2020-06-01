variable "instance_ami" {
  description = "AMI for aws EC2 instance"
  default     = "ami-098f16afa9edf40be"
}
variable "instance_type" {
  description = "type for aws EC2 instance"
  default     = "t2.small"
}
variable "users" {
  default = "ec2-user"
}
variable "subnet_id" {
  default = "subnet-28242f06"
}
