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

locals {
  cluster_namespace      = "${var.shard_name}-${var.cluster_namespace_suffix}"
  workload_iam_member_id = format("principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/%s", var.project_number, var.project_id, local.cluster_namespace, var.cluster_service_account)
}

resource "google_project_service" "service" {
  for_each = toset([
    "spanner.googleapis.com",       // For Spanner database. roles/spanner.admin
    "storage.googleapis.com",       // For GCS bucket. roles/storage.admin
    "cloudkms.googleapis.com",      // For KMS keyring and crypto key. roles/cloudkms.admin
    "secretmanager.googleapis.com", // For Secret manager if log is using Secret Manager instead of KMS. roles/secretmanager.admin
  ])
  project = var.project_id
  service = each.key

  // Do not disable the service on destroy. On destroy, we are going to
  // destroy the project, but we need the APIs available to destroy the
  // underlying resources.
  disable_on_destroy = false
}
