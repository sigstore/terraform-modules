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

resource "google_secret_manager_secret" "private-key" {
  count   = var.enable_secrets ? 1 : 0
  project = var.project_id

  secret_id = "${var.shard_name}-${var.dns_subdomain_name}-private"

  replication {
    auto {}
  }
  depends_on = [google_project_service.service]
}

resource "google_secret_manager_secret" "public-key" {
  count   = var.enable_secrets ? 1 : 0
  project = var.project_id

  secret_id = "${var.shard_name}-${var.dns_subdomain_name}-public"

  replication {
    auto {}
  }
  depends_on = [google_project_service.service]
}

resource "google_project_iam_member" "secret-getter" {
  count   = var.enable_secrets ? 1 : 0
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = local.workload_iam_member_id
}
