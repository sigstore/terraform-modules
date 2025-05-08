/**
 * Copyright 2025 The Sigstore Authors
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

resource "google_storage_bucket" "tessera_store" {
  project                     = var.project_id
  name                        = "${var.shard_name}-${var.bucket_name_suffix}"
  location                    = var.region
  storage_class               = var.storage_class
  uniform_bucket_level_access = true
  depends_on                  = [google_project_service.service]
}

resource "google_storage_bucket_iam_member" "gcs_user" {
  bucket = google_storage_bucket.tessera_store.name
  role   = "roles/storage.objectUser"
  member = local.workload_iam_member_id

  depends_on = [google_storage_bucket.tessera_store]
}

resource "google_storage_bucket_iam_member" "public_reader" {
  bucket = google_storage_bucket.tessera_store.name
  role   = "roles/storage.objectViewer"
  member = var.public_bucket_member

  depends_on = [google_storage_bucket.tessera_store]
}
