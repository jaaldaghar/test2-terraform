# GCP Storage Bucket

This module allows creation of a GCS bucket and enables access by a service account.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13 |
| google | >= 3.36 |

## Providers

| Name | Version |
|------|---------|
| google | >= 3.36 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bucket\_name | This must be a unique name | `any` | n/a | yes |
| force\_destroy\_property | n/a | `string` | `"false"` | no |
| labels | Map of labels to be used on all instances | `map` | `{}` | no |
| lifecycle\_rules | List of a map for each lifecycle rule to apply to this bucket. See module README for more details. | `list(any)` | `[]` | no |
| location | n/a | `any` | `null` | no |
| log\_bucket\_name | This must be a unique name. Bucket where logs are kept | `string` | `""` | no |
| project\_id | The project in which the resource belongs. If it is not provided, the provider project is used. | `string` | `null` | no |
| role | Role to provide service account access to bucket | `string` | n/a | yes |
| sa\_email | Email address of service sccount | `string` | n/a | yes |
| storage\_class | n/a | `string` | `"REGIONAL"` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket\_name | n/a |

## Example Usage
To be called in the main.tf file in the resources directory

```hcl
module "gcs_bucket_useast1" {
  source                 = "../../modules/storagebucket"
  project_id             = "${var.project_id}"
  location               = "${var.region}"
  bucket_name            = "${var.project_id}-test-bucket-${var.region}"
  sa_email               = "${module.gcp_service_account.service_account_email}"
  role                   = "roles/storage.objectViewer"
  force_destroy_property = true

  lifecycle_rules = [
    {
      action = {
        type = "Delete"
      }
      condition = {
        age = 500
      }
    },
    {
      action = {
        type          = "SetStorageClass"
        storage_class = "COLDLINE"
      }
      condition = {
        created_before = "2020-01-31"
      }
    }
  ]

  labels = {
    environment = "test"
  }
}
```

## Lifecycle Rules block

The optional `lifecycle_rules` input variable expects a list of map objects. Each map in the list must also contain an `action` map and a `condition` map. The `action` map specifies whether this is a rule that deletes or sets the storage class for objects, and the `condition` map specifies the requires to take that action.

This variable is set up to basically duplicate the way the `lifecycle_rule` block works in the [storage bucket resource](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket#lifecycle_rule). Since it's a block configuration, we have to use a dynamic block in this module to set it up.

See the [documentation for the lifecycle rule in the storage bucket resource](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket#lifecycle_rule) for more information about the structure and requirements.


Supported `action` map items:
* `type` (Required) - `Delete` or `SetStorageClass`
* `storage_class` (Required if action type is SetStorageClass) - the storage class to set using this rule

Supported `condition` map items are below. If more than one item is listed in this map, they must all be true for this rule to trigger.
* `age` - (Optional) Minimum age of an object in days to satisfy this condition.
* `created_before` - (Optional) Creation date of an object in RFC 3339 (e.g. 2017-06-13) to satisfy this condition.
* `with_state` - (Optional) Match to live and/or archived objects. Unversioned buckets have only live objects. See [documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket#lifecycle_rule) for supported values.
* `matches_storage_class` - (Optional) Storage Class of objects to satisfy this condition. See [documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket#lifecycle_rule) for supported values.
* `num_newer_versions` - (Optional) Relevant only for versioned objects. The number of newer versions of an object to satisfy this condition.


### Example lifecycle_rules variable inputs

#### Delete if 500 days old or older, and set to coldline if 60 days or older
```hcl
  lifecycle_rules = [
    {
      action = {
        type = "Delete"
      }
      condition = {
        age = "500"
      }
    },
    {
      action = {
        type          = "SetStorageClass"
        storage_class = "COLDLINE"
      }
      condition = {
        age = "60"
      }
    }
  ]
```

#### Delete nearline and coldline files that are 500 days old or older
```hcl
  lifecycle_rules = [
    {
      action = {
        type = "Delete"
      }
      condition = {
        age = "500"
        matches_storage_class = ["NEARLINE", "COLDLINE"]
      }
    }
  ]
```

## Copyright

Copyright 2020 [Cloudreach](https://www.cloudreach.com)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.