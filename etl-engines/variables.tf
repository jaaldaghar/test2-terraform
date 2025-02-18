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
# Make a varaible for environment and application name.
variable "environment" {
  type        = string
  description = "SDLC Environment where the resources will be deployed."
}

variable "application" {
  type        = string
  description = "Name of the application."
}
