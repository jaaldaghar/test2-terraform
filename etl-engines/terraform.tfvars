project_id                  = "ut-udot-deloittedatasnbx-dev"
shared_vpc_project          = "ut-udot-shared-vpc-dev"
shared_vpc_subnet_self_link = "https://www.googleapis.com/compute/v1/projects/ut-udot-shared-vpc-dev/regions/us-central1/subnetworks/ut-udot-shared-vpc-dev-subnet"
environment                 = "dev"
application                 = "deloittesnbx"
user_groups = [
  "gcp-udot-deloitte-data-mgmt@utah.gov",
  "gcp-udot-devops@utah.gov"
]
