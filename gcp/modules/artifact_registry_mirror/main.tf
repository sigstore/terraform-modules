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

// Enable required services for this module
resource "google_project_service" "service" {
  for_each = toset([
    "artifactregistry.googleapis.com", // For remote repositories
  ])
  project = var.project_id
  service = each.key

  // Do not disable the service on destroy. On destroy, we are going to
  // destroy the project, but we need the APIs available to destroy the
  // underlying resources.
  disable_on_destroy = false
}

locals {
  // Flatten the repository to readers map to a list so we can use for_each
  // expansion, granting reader per repository rather than at project level.
  repository_reader_list = flatten([
    for repository_id, upstream in var.upstreams : [
      for member in upstream.readers : {
        repository_id = repository_id
        member        = member
      }
    ]
  ])
}

resource "google_artifact_registry_repository" "remote" {
  for_each = var.upstreams

  project       = var.project_id
  location      = var.location
  repository_id = each.key
  description   = each.value.description
  format        = "DOCKER"
  mode          = "REMOTE_REPOSITORY"

  // Mirrored artifacts are already scanned at their upstream home, and scanning
  // is billed per repository, so rescanning the cached copy is duplicate spend.
  vulnerability_scanning_config {
    enablement_config = "DISABLED"
  }

  cleanup_policy_dry_run = each.value.cleanup_policy_dry_run

  // older_than counts from when a version was first cached here, not from when
  // it was last pulled
  cleanup_policies {
    id     = "delete-stale-cached-versions"
    action = "DELETE"

    condition {
      older_than = each.value.delete_older_than
    }
  }

  // Keep wins over delete, so these survive the age rule no matter how long they
  // have been cached.
  cleanup_policies {
    id     = "keep-current-versions"
    action = "KEEP"

    most_recent_versions {
      keep_count = each.value.keep_most_recent_versions
    }
  }

  remote_repository_config {
    common_repository {
      uri = each.value.uri
    }
  }

  depends_on = [google_project_service.service]
}

resource "google_artifact_registry_repository_iam_member" "reader" {
  // Use "<repository> <member>" as the unique key for each binding. Neither can
  // contain whitespace so this is guaranteed to be unique.
  for_each = {
    for binding in local.repository_reader_list :
    "${binding.repository_id} ${binding.member}" => binding
  }

  project    = var.project_id
  location   = var.location
  repository = google_artifact_registry_repository.remote[each.value.repository_id].repository_id
  role       = "roles/artifactregistry.reader"
  member     = each.value.member
}
