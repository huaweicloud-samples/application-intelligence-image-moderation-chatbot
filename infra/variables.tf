variable "region" {
  description = "华为云区域"
  type        = string
  default     = "cn-north-4"
}

variable "project_name" {
  description = "项目名称"
  type        = string
  default     = "image-moderator"
}

variable "vpc_name" {
  description = "VPC 名称"
  type        = string
  default     = "image-moderator-vpc"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_name" {
  description = "子网名称"
  type        = string
  default     = "image-moderator-subnet"
}

variable "subnet_cidr" {
  description = "子网 CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

variable "verification_token" {
  description = "Slack verification token"
  type        = string
  sensitive   = true
}

variable "access_token" {
  description = "Slack OAuth access token"
  type        = string
  sensitive   = true
}

variable "min_confidence" {
  description = "Minimum confidence threshold for image moderation"
  type        = number
  default     = 80
}

variable "hw_access_key" {
  description = "华为云 Access Key"
  type        = string
  sensitive   = true
}

variable "hw_secret_key" {
  description = "华为云 Secret Key"
  type        = string
  sensitive   = true
}

variable "hw_project_id" {
  description = "华为云 Project ID"
  type        = string
  sensitive   = true
}
