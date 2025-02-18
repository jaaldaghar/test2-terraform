terraform {
  backend "gcs" {
    bucket = "ut-udot-deloittedatasnbx-dev-tfstate"
    prefix = "notebooks"
  }
}
