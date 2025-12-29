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

module "slos" {
  source = "../slo"
  count  = var.create_slos ? 1 : 0

  project_id            = var.project_id
  project_number        = var.project_number
  service_id            = "rekor_v2_global_lb_view"
  display_name          = "Rekor V2 Reads"
  resource_name         = "" # no telementry, this isn't a service
  notification_channels = local.notification_channels
  severity              = "warning"

  availability_slos = {
    gcs-read-availability = {
      display_prefix            = "Rekor V2 Read Availability"
      base_total_service_filter = "metric.type=\"loadbalancing.googleapis.com/https/request_count\" resource.type=\"https_lb_rule\""
      # Only count 500s as server errors since clients can trigger 400s.
      bad_filter = "metric.labels.response_code=monitoring.regex.full_match(\"5[0-9][0-9]\")"
      slos = {
        api-v2-read = {
          display_suffix = "/api/v2/{path=**} - GCS Reads"
          label_filter   = "resource.labels.forwarding_rule_name=monitoring.regex.full_math(\".*-rekor-https-forwarding-rule\") resource.labels.matched_url_path_rule=\"/api/v2/{path=**}\""
          goal           = 0.995
        },
      }
    }
  }
}
