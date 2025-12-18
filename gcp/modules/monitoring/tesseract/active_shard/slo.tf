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
  source = "../../slo"
  count  = var.create_slos ? 1 : 0

  project_id            = var.project_id
  project_number        = var.project_number
  service_id            = "${var.shard_name}-ctlog"
  display_name          = "CT log (TesseraCT) - ${var.shard_name}"
  resource_name         = format("//container.googleapis.com/projects/%s/locations/%s/clusters/%s/k8s/namespaces/%s-%s", var.project_id, var.cluster_location, var.cluster_name, var.shard_name, var.gke_namespace_suffix)
  notification_channels = local.notification_channels

  availability_slos = {
    http-server-availability = {
      display_prefix            = "Availability (HTTP Server)"
      base_total_service_filter = "metric.type=\"workload.googleapis.com/tesseract.http.response.count\" resource.type=\"k8s_cluster\""
      # Only count 500s as server errors since clients can trigger 400s.
      bad_filter = "metric.labels.http_response_status_code=monitoring.regex.full_match(\"5[0-9][0-9]\")"
      slos = {
        pre-chain-post = {
          display_suffix = "/ct/v1/add-pre-chain - POST"
          label_filter   = "metric.labels.tesseract_operation=\"AddPreChain\""
          goal           = 0.995
        },
      },
    }
  }
}
