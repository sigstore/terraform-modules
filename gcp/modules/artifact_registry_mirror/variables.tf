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

variable "project_id" {
  description = "Project in which the mirror repositories are created"
  type        = string
  validation {
    condition     = length(var.project_id) > 0
    error_message = "Must specify project_id variable."
  }
}

variable "location" {
  description = "Artifact Registry location: https://docs.cloud.google.com/artifact-registry/docs/repositories/repo-locations"
  type        = string
}

variable "upstreams" {
  description = <<-EOT
    Remote repositories to create, keyed by Artifact Registry repository ID.

    uri                       - upstream registry, e.g. "https://ghcr.io"
    description               - shown on the repository
    readers                   - IAM members granted roles/artifactregistry.reader
                                on this repository only
    delete_older_than         - evict cached versions this long after they were
                                first cached, e.g. "2592000s" or "30d"
    keep_most_recent_versions - versions per package exempted from that eviction.
                                This, not the age window, is what keeps a running
                                image cached.
    cleanup_policy_dry_run    - log what eviction would delete instead of deleting
                                it. Results land in Data Access audit logs about a
                                day later, not in the plan.
  EOT

  type = map(object({
    uri                       = string
    description               = optional(string, "")
    readers                   = optional(set(string), [])
    delete_older_than         = optional(string, "2592000s")
    keep_most_recent_versions = optional(number, 5)
    cleanup_policy_dry_run    = optional(bool, false)
  }))

  validation {
    condition     = alltrue([for u in var.upstreams : startswith(u.uri, "https://")])
    error_message = "Each upstream uri must be an https:// URL."
  }

  validation {
    condition     = alltrue([for u in var.upstreams : u.keep_most_recent_versions > 0])
    error_message = "keep_most_recent_versions must be greater than 0; zero exempts nothing from delete_older_than."
  }
}
