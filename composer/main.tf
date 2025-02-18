locals {
  long_app_name           = "ut-udot-composer-poc-${var.environment}"
  composer_version_string = "composer-2.9.11-airflow-2.10.2"
  vpc_name                = "${local.long_app_name}-cloud-vpc"
  subnet = {
    name = "${local.long_app_name}-${var.region}-subnet"
    cidr = "192.168.1.0/24"
  }
  pod_range = {
    name = "${local.long_app_name}-composer-pods"
    cidr = "192.168.8.0/21"
  }
  service_range = {
    name = "${local.long_app_name}-composer-svcs"
    cidr = "192.168.2.0/24"
  }
  common_labels = {
    environment = var.environment
    created_by  = "terraform"
    repo        = "udot-deloitte-infra"
  }
  worker = {
    cpu        = 2
    max_count  = 6
    memory_gb  = 7.5
    min_count  = 2
    storage_gb = 10
  }
  composer_project_roles = [
    "roles/composer.worker",
    "roles/dataflow.admin",
    "roles/dataflow.worker",
    "roles/storage.admin",
    "roles/secretmanager.secretAccessor",
    "roles/bigquery.admin",
    "roles/compute.networkUser"
  ]
  data_bucket_prefix = local.long_app_name
  deloitte_group     = "gcp-udot-deloitte-data-mgmt@utah.gov"
}

data "google_project" "project" {
  project_id = var.project_id
}


data "google_compute_subnetwork" "shared_subnet" {
  project = "ut-udot-shared-vpc-${var.environment}"
  name    = "ut-udot-shared-vpc-${var.environment}-subnet"
  region  = var.region
}
##### GCS BUCKETS #######
module "gcs_dropzone_bucket" {
  source        = "../modules/storagebucket"
  project_id    = var.project_id
  location      = var.region
  bucket_name   = "${local.data_bucket_prefix}-dropzone"
  sa_email      = google_service_account.airflow_worker.email
  role          = "roles/storage.objectAdmin"
  storage_class = var.storage_class

  # Do not delete bucket if it contains files
  force_destroy_property = false

  labels = merge(
    local.common_labels
    # Add resource-specific labels here
  )
}

###### Cloud Only VPC ##########
resource "google_compute_network" "cloud_only_vpc" {
  name                    = local.vpc_name
  project                 = var.project_id
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
  description             = "VPC with cloud only subnets that cannot be routed to the state network."
}

resource "google_compute_subnetwork" "cloud_only_subnet" {
  name                     = local.subnet.name
  project                  = var.project_id
  region                   = var.region
  ip_cidr_range            = local.subnet.cidr
  network                  = google_compute_network.cloud_only_vpc.self_link
  private_ip_google_access = true
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = "1.0"
    metadata             = "INCLUDE_ALL_METADATA"
    metadata_fields      = []
  }
  secondary_ip_range {
    range_name    = local.pod_range.name
    ip_cidr_range = local.pod_range.cidr
  }
  secondary_ip_range {
    range_name    = local.service_range.name
    ip_cidr_range = local.service_range.cidr
  }

  lifecycle {
    ignore_changes = [
      log_config,
      description
    ]
  }
}

###### Composer V2 ##############
resource "google_service_account" "airflow_worker" {
  project      = var.project_id
  account_id   = "composer-poc-${var.environment}"
  display_name = "composer-poc-${var.environment}"
  description  = "Account for Deloitte POC Composer cluster"
}

resource "google_project_iam_member" "composer-worker" {
  for_each = toset(local.composer_project_roles)
  project  = data.google_project.project.id
  role     = each.value
  member   = "serviceAccount:${google_service_account.airflow_worker.email}"
}

# Must add this role prior to trying to spin up a composer enviroment
resource "google_project_iam_member" "composer-sa" {
  project = data.google_project.project.id
  role    = "roles/composer.ServiceAgentV2Ext"
  member  = "serviceAccount:service-${data.google_project.project.number}@cloudcomposer-accounts.iam.gserviceaccount.com"
}

resource "google_compute_subnetwork_iam_member" "member" {
  project    = data.google_compute_subnetwork.shared_subnet.project
  region     = data.google_compute_subnetwork.shared_subnet.region
  subnetwork = data.google_compute_subnetwork.shared_subnet.self_link
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:${google_service_account.airflow_worker.email}"
}

module "composer-v2" {
  source                           = "terraform-google-modules/composer/google//modules/create_environment_v2"
  project_id                       = var.project_id
  composer_env_name                = local.long_app_name
  image_version                    = local.composer_version_string
  region                           = var.region
  composer_service_account         = google_service_account.airflow_worker.email
  network                          = google_compute_network.cloud_only_vpc.name
  subnetwork                       = google_compute_subnetwork.cloud_only_subnet.name
  pod_ip_allocation_range_name     = local.pod_range.name
  service_ip_allocation_range_name = local.service_range.name
  grant_sa_agent_permission        = false
  environment_size                 = "ENVIRONMENT_SIZE_SMALL"
  env_variables = {
    AIRFLOW_VAR_REGION               = var.region
    AIRFLOW_VAR_PROJECT_ID           = var.project_id
    AIRFLOW_VAR_NETWORK_URL          = data.google_compute_subnetwork.shared_subnet.network
    AIRFLOW_VAR_SUBNETWORK_URL       = data.google_compute_subnetwork.shared_subnet.self_link
    AIRFLOW_VAR_DROPZONE_BUCKET_NAME = module.gcs_dropzone_bucket.bucket_name
  }
  worker = local.worker
  labels = merge(
    local.common_labels
    # Add resource-specific labels here
  )
  depends_on = [
    google_project_iam_member.composer-sa
  ]
}

resource "google_project_iam_member" "composer_user" {
  project = data.google_project.project.id
  role    = "roles/composer.user"
  member  = "group:${local.deloitte_group}"
}

# Add a way to give composer service account user role on dataflow worker service account.
