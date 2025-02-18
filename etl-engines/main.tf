locals {
  dataflow_worker_roles = ["roles/bigquery.admin", "roles/dataflow.worker", "roles/storage.objectAdmin"]
}

data "google_compute_subnetwork" "subnet" {
  self_link = var.shared_vpc_subnet_self_link
}


# create new service account to used as a dataflow worker
resource "google_service_account" "dataflow_worker" {
  project      = var.project_id
  account_id   = "dataflow-${var.application}-${var.environment}"
  display_name = "dataflow-${var.application}-${var.environment}"
  description  = "Account for Deloitte POC Dataflow worker"
}


# create a bucket to be used as the dataflow staging bucket
module "dataflow_tempfile_bucket" {
  source        = "../modules/storagebucket"
  project_id    = var.project_id
  location      = data.google_compute_subnetwork.subnet.region
  bucket_name   = "ut-udot-${var.application}-${var.environment}-tempfiles"
  sa_email      = google_service_account.dataflow_worker.email
  role          = "roles/storage.objectAdmin"
  storage_class = "STANDARD"

  # Do not delete bucket if it contains files
  force_destroy_property = false
  lifecycle_rules = [
    {
      action = {
        type = "Delete"
      }
      condition = {
        age = "30"
      }
    }
  ]
}

# Consolidate the 3 project roles below into one resource by using for_each iteration
resource "google_project_iam_member" "dataflow_worker_roles" {
  for_each = toset(local.dataflow_worker_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.dataflow_worker.email}"
}

#Give the dataflow worker the role required to access secrets in secret manager
resource "google_project_iam_member" "dataflow_worker_secrets_access" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.dataflow_worker.email}"
}

# bucket roles
resource "google_storage_bucket_iam_member" "dataflow_worker_bucket" {
  bucket = module.dataflow_tempfile_bucket.bucket_name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.dataflow_worker.email}"
}

# Shared VPC roles
data "google_compute_subnetwork" "workbench_subnet" {
  self_link = var.shared_vpc_subnet_self_link
}

resource "google_project_iam_member" "project" {
  for_each = toset(var.user_groups)
  project  = var.project_id
  role     = "roles/compute.networkViewer"
  member   = "group:${each.value}"
}

resource "google_compute_subnetwork_iam_member" "member" {
  for_each   = toset(var.user_groups)
  project    = var.shared_vpc_project
  region     = data.google_compute_subnetwork.workbench_subnet.region
  subnetwork = data.google_compute_subnetwork.workbench_subnet.name
  role       = "roles/compute.networkUser"
  member     = "group:${each.value}"
}

#Give the dataflow_worker service account the same network viewer and network user roles as above
resource "google_project_iam_member" "dataflow_worker_project_network_viewer" {
  project = var.shared_vpc_project
  role    = "roles/compute.networkViewer"
  member  = "serviceAccount:${google_service_account.dataflow_worker.email}"
}

resource "google_compute_subnetwork_iam_member" "dataflow_worker_subnet" {
  project    = var.shared_vpc_project
  region     = data.google_compute_subnetwork.workbench_subnet.region
  subnetwork = data.google_compute_subnetwork.workbench_subnet.name
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:${google_service_account.dataflow_worker.email}"
}

# give a list of user groups service account user roles on the new dataflow service so that they can deploy jobs
resource "google_service_account_iam_member" "dataflow_worker_user" {
  for_each           = toset(var.user_groups)
  service_account_id = google_service_account.dataflow_worker.name
  role               = "roles/iam.serviceAccountUser"
  member             = "group:${each.key}"
}

output "dataflow_worker_email" {
  value = google_service_account.dataflow_worker.email
}

output "dataflow_worker_bucket" {
  value = module.dataflow_tempfile_bucket.bucket_name
}
