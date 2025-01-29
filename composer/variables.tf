variable "environment" {
  type        = string
  description = "Name of this environment. Used in resource names."
}

variable "project_id" {
  type        = string
  description = "GCP Project ID for this environment."
}

variable "region" {
  type        = string
  description = "Default region."
}

variable "storage_class" {
  type        = string
  description = "Default storage class for buckets in this environment."
}
