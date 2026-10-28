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
  slo_display_prefix    = var.service_display_name == "Rekor v2" ? "Rekor V2" : var.service_display_name
  all_shards            = concat(var.active_shards, var.frozen_shards)
  forwarding_rule_regex = "(${join("|", local.all_shards)})-rekor-https-forwarding-rule"
}

module "slos" {
  source = "../../slo"
  count  = var.create_slos && length(local.all_shards) > 0 ? 1 : 0

  project_id            = var.project_id
  project_number        = var.project_number
  service_id            = var.slo_service_id
  display_name          = "${local.slo_display_prefix} Reads"
  resource_name         = "" # no telemetry, this isn't a service
  notification_channels = local.notification_channels
  severity              = "warning"

  availability_slos = {
    gcs-read-availability = {
      display_prefix            = "${local.slo_display_prefix} Read Availability"
      base_total_service_filter = "metric.type=\"loadbalancing.googleapis.com/https/request_count\" resource.type=\"https_lb_rule\""
      # Only count 500s as server errors since clients can trigger 400s.
      bad_filter = "metric.labels.response_code_class=500"
      slos = {
        api-v2-read = {
          display_suffix = "GCS Reads"
          label_filter   = "resource.labels.forwarding_rule_name=monitoring.regex.full_match(\"${local.forwarding_rule_regex}\") resource.labels.backend_target_type=\"BACKEND_BUCKET\""
          goal           = 0.995
        },
      }
    }
  }
}
