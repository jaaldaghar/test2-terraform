# Create a GCS bucket
resource "google_storage_bucket" "gcs-bucket" {
  name          = var.bucket_name
  location      = var.location
  storage_class = var.storage_class
  project       = var.project_id
  force_destroy = var.force_destroy_property
  labels        = var.labels

  versioning {
    enabled = true
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      action {
        type = lookup(lifecycle_rule.value["action"], "type")

        # Only required if type = SetStorageClass
        storage_class = lookup(lifecycle_rule.value["action"], "storage_class", null)
      }

      # At least one condition must exist
      condition {
        age                   = lookup(lifecycle_rule.value["condition"], "age", null)
        created_before        = lookup(lifecycle_rule.value["condition"], "created_before", null)
        with_state            = lookup(lifecycle_rule.value["condition"], "with_state", null)
        matches_storage_class = lookup(lifecycle_rule.value["condition"], "matches_storage_class", null)
        num_newer_versions    = lookup(lifecycle_rule.value["condition"], "num_newer_versions", null)
      }
    }
  }
}

resource "google_storage_bucket_iam_binding" "view_policy" {
  bucket  = google_storage_bucket.gcs-bucket.name
  role    = var.role
  members = ["serviceAccount:${var.sa_email}"]
}