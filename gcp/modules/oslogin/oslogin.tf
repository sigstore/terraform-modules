/**
 * Copyright 2022 The Sigstore Authors
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

// Enable required services for this module
resource "google_project_service" "service" {
  for_each = toset([
    "compute.googleapis.com", // For compute project metadata, granting oslogin roles.
  ])
  service = each.key

  // Do not disable the service on destroy. On destroy, we are going to
  // destroy the project, but we need the APIs available to destroy the
  // underlying resources.
  disable_on_destroy = false
}

// Configure oslogin at the project level for all VMs
resource "google_compute_project_metadata_item" "oslogin_enable" {
  count = var.oslogin.enabled ? 1 : 0

  project = var.project_id
  key     = "enable-oslogin"
  value   = "TRUE"
}

// Configure oslogin at the project level with 2fa for all VMs
resource "google_compute_project_metadata_item" "oslogin_enable_2fa" {
  count = var.oslogin.enabled && var.oslogin.enabled_with_2fa ? 1 : 0

  project = var.project_id
  key     = "enable-oslogin-2fa"
  value   = "TRUE"
}
