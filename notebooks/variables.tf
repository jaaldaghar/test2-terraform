variable "project_id" {
  type        = string
  description = "Project where the Notebook API will be enabled."
}

# variable "region" {
#   type        = string
#   description = "Compute region where workbench instances will be created."
# }

variable "shared_vpc_project" {
  type        = string
  description = "Project where subnet exists."
  default     = null
}

variable "shared_vpc_subnet_self_link" {
  type        = string
  description = "Subnet to use for compute resources."
}

variable "user_groups" {
  type        = list(string)
  description = "List of user group emails that need notebook service accounts."
}
