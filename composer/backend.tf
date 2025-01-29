terraform {
  required_version = "~> 1.7.1"

  backend "gcs" {
    bucket = "ut-udot-deloittedatasnbx-dev-tfstate"
    prefix = "composer"
  }
}
