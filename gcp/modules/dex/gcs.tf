/**
 * Copyright 2026 The Sigstore Authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  workload_iam_member_id = format("principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/%s", var.project_number, var.project_id, var.cluster_namespace, var.cluster_service_account)
}

# Grant the K8s workload identity direct permission to push keys to the bucket
resource "google_storage_bucket_iam_member" "k8s_pusher_access" {
  count = var.single_region ? 0 : 1

  bucket = var.bucket_name
  role   = "roles/storage.objectUser"
  member = local.workload_iam_member_id
}

data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "${path.module}/src/jwks-merger"
  output_path = "${path.module}/jwks-merger.zip"
}

resource "google_storage_bucket_object" "function_zip" {
  count = var.single_region ? 0 : 1

  name   = "source/jwks-merger-${data.archive_file.function_source.output_md5}.zip"
  bucket = var.bucket_name
  source = data.archive_file.function_source.output_path
}

resource "google_cloudfunctions2_function" "jwks_merger" {
  count = var.single_region ? 0 : 1

  project = var.project_id

  name     = "dex-jwks-merger"
  location = var.region

  build_config {
    runtime     = "go125"
    entry_point = "MergeKeys"
    source {
      storage_source {
        bucket = var.bucket_name
        object = google_storage_bucket_object.function_zip[count.index].name
      }
    }
  }

  event_trigger {
    trigger_region = "us"
    event_type     = "google.cloud.storage.object.v1.finalized"
    event_filters {
      attribute = "bucket"
      value     = var.bucket_name
    }
  }
}
