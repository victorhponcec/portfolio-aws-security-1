variable "region1" {
  description = "main region"
  type        = string
  default     = "us-east-1"
}

variable "az1" {
  description = "availability zone 1"
  type        = string
  default     = "us-east-1a"
}

variable "az2" {
  description = "availability zone 2"
  type        = string
  default     = "us-east-1b"
}

variable "email" {
  description = "email for sns"
  default     = "victortest@gmail.com"
}