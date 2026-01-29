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
  prober_url = var.prober_url != "" ? var.prober_url : format("http://rekor-tiles-%s.%s-rekor-tiles-system.svc", var.shard_name, var.shard_name)
}

module "slos" {
  source = "../../slo"
  count  = var.create_slos ? 1 : 0

  project_id            = var.project_id
  project_number        = var.project_number
  service_id            = "${var.shard_name}-rekorv2"
  display_name          = "Rekor v2 - ${var.shard_name}"
  resource_name         = format("//container.googleapis.com/projects/%s/locations/%s/clusters/%s/k8s/namespaces/%s-%s", var.project_id, var.cluster_location, var.cluster_name, var.shard_name, var.gke_namespace_suffix)
  notification_channels = local.notification_channels

  availability_slos = {
    http-server-availability = {
      display_prefix            = "Availability (HTTP Server)"
      base_total_service_filter = "metric.type=\"prometheus.googleapis.com/rekor_v2_http_requests_total/counter\" resource.type=\"prometheus_target\""
      # Only count 500s as server errors since clients can trigger 400s.
      bad_filter = "metric.labels.code=monitoring.regex.full_match(\"5[0-9][0-9]\")"
      slos = {
        api-v2-log-entries-post = {
          display_suffix = "/api/v2/log/entries - POST"
          label_filter   = "metric.labels.method=\"post\""
          goal           = 0.995
        },
      },
    },
    grpc-server-availability = {
      display_prefix            = "Availability (gRPC Server)"
      base_total_service_filter = format("metric.type=\"prometheus.googleapis.com/grpc_server_handled_total/counter\" resource.type=\"prometheus_target\" resource.labels.namespace=\"%s-%s\"", var.shard_name, var.gke_namespace_suffix)
      bad_filter                = "metric.labels.grpc_method=one_of(\"DeadlineExceeded\",\"Internal\")"
      slos = {
        api-v2-log-entries-post = {
          display_suffix = "Create Entry"
          label_filter   = "metric.labels.grpc_service=\"dev.sigstore.rekor.v2.Rekor\" metric.labels.grpc_method=\"CreateEntry\""
          goal           = 0.995
        },
      },
    },
    prober-availability = {
      display_prefix            = "Availability (Prober)"
      base_total_service_filter = format("metric.type=\"prometheus.googleapis.com/api_endpoint_latency_count/summary\" resource.type=\"prometheus_target\" metric.labels.host=\"%s\"", local.prober_url)
      bad_filter                = "metric.labels.status_code!=monitoring.regex.full_match(\"20[0-1]\")"
      slos = {
        api-v2-log-entries-post = {
          display_suffix = "/api/v2/log/entries - POST"
          label_filter   = "metric.labels.endpoint=\"/api/v2/log/entries\" metric.labels.method=\"POST\""
          goal           = 0.995
        },
      }
    }
  }
}
