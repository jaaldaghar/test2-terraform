locals {
  vertex_apis = ["notebooks.googleapis.com", "aiplatform.googleapis.com", "servicenetworking.googleapis.com", "secretmanager.googleapis.com"]
}

provider "google" {
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_project_service" "service" {
  for_each           = toset(local.vertex_apis)
  service            = each.key
  project            = data.google_project.project.id
  disable_on_destroy = false
}

resource "time_sleep" "wait_project_init" {
  create_duration = "30s"
  depends_on      = [google_project_service.service]
}

resource "google_project_iam_member" "notebook_service_network_user" {
  project = var.shared_vpc_project
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-notebooks.iam.gserviceaccount.com"
}

module "workbench_instance_deliotte" {
  source                       = "/Users/kwalker/Documents/repos/gcp-terraform-modules/terraform-vertex-instance" #"../modules/vertex-instance"
  project_id                   = data.google_project.project.project_id
  notebook_name_prefix         = "deloitte"
  shared_vpc_project           = var.shared_vpc_project
  notebook_vpc_subnet_selflink = var.shared_vpc_subnet_self_link
  user_groups                  = var.user_groups
  depends_on                   = [google_project_iam_member.notebook_service_network_user, google_project_service.service]
}

output "notebook_account_email" {
  value = module.workbench_instance_deliotte.notebook_account_email
}
