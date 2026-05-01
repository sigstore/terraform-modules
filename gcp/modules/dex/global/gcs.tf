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

resource "google_storage_bucket" "auth_bucket" {
  project = var.project_id

  name     = "${var.project_id}-dex-jwks-storage"
  location = "US"

  uniform_bucket_level_access = true
}

# Grant the global internet permission to read the merged keys file via the CDN
resource "google_storage_bucket_iam_member" "public_read_access" {
  bucket = google_storage_bucket.auth_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Grant the default compute service account (which runs the Cloud Function) access
resource "google_storage_bucket_iam_member" "function_bucket_access" {
  bucket = google_storage_bucket.auth_bucket.name
  role   = "roles/storage.objectUser"
  member = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

# Grant the Eventarc Service Agent its required project-level role
resource "google_project_iam_member" "eventarc_service_agent" {
  project = var.project_id
  role    = "roles/eventarc.serviceAgent"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-eventarc.iam.gserviceaccount.com"
}

data "google_storage_project_service_account" "gcs_account" {
  project = var.project_id
}

# Grant the project's hidden Cloud Storage agent permission to publish to Pub/Sub
resource "google_project_iam_member" "gcs_pubsub_publishing" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}
