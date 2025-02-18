# Required Variables
variable "bucket_name" {
  description = "This must be a unique name"
}

variable "sa_email" {
  description = "Email address of service sccount"
  type        = string
}

variable "role" {
  description = "Role to provide service account access to bucket"
  type        = string
}


# Optional Variables
variable "project_id" {
  type        = string
  description = "The project in which the resource belongs. If it is not provided, the provider project is used."
  default     = null
}

variable "log_bucket_name" {
  description = "This must be a unique name. Bucket where logs are kept"
  default     = ""
}

variable "location" {
  default = null
}

variable "storage_class" {
  default = "REGIONAL"
}

variable "force_destroy_property" {
  default = "false"
}

variable "labels" {
  description = "Map of labels to be used on all instances"
  type        = map
  default     = {}
}

variable "lifecycle_rules" {
  # Use 'any' as the data type since we have a map with the format <tag name> = { tag details }
  type        = list(any)
  description = "List of a map for each lifecycle rule to apply to this bucket. See module README for more details."

  default = []
}