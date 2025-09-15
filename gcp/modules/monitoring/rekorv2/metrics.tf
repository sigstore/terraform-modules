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

resource "google_logging_metric" "rekorv2_k8s_pod_restart_failing_container" {
  description = "Counts the number of logs that contain the \"restarting failed container\" message"
  filter      = "resource.labels.namespace_name=\"${var.shard_name}-${var.gke_namespace_suffix}\"\nresource.type=k8s_pod AND severity>=WARNING\n\"Back-off restarting failed container\"\n"

  metric_descriptor {
    metric_kind = "DELTA"
    unit        = "1"
    value_type  = "INT64"
  }

  name    = "rekorv2-${var.shard_name}/k8s_pod/restarting-failed-container"
  project = var.project_id
}

resource "google_logging_metric" "k8s_pod_unschedulable" {
  description = "Counts the number of k8s_pod resource logs that contain the message \"unschedulable\""
  filter      = "resource.labels.namespace_name=\"${var.shard_name}-${var.gke_namespace_suffix}\"\nresource.type=k8s_pod AND severity>=WARNING\n\"unschedulable\"\n"

  metric_descriptor {
    metric_kind = "DELTA"
    unit        = "1"
    value_type  = "INT64"
  }

  name    = "rekorv2-${var.shard_name}/k8s_pod/unschedulable"
  project = var.project_id
}

resource "google_logging_metric" "rekor_v2_lb_requests" {
  project     = var.project_id
  name        = "rekorv2-${var.shard_name}/lb_requests"
  description = "Counts the requests at the load balancer"
  filter      = "httpRequest.requestUrl=~\"^https://${var.shard_name}\\.rekor\\.sigstage\\.dev\" AND resource.type=\"http_load_balancer\""

  metric_descriptor {
    metric_kind = "DELTA"
    unit        = "1"
    value_type  = "INT64"
    labels {
      key        = "cache_hit"
      value_type = "BOOL"
    }
    labels {
      key        = "cache_lookup"
      value_type = "BOOL"
    }
    labels {
      key        = "http_method"
      value_type = "STRING"
    }
    labels {
      key        = "http_status"
      value_type = "INT64"
    }
    labels {
      key        = "user_agent_client"
      value_type = "STRING"
    }
    labels {
      key        = "user_agent_version"
      value_type = "STRING"
    }

    labelExtractors = {
      "cache_hit"          = EXTRACT(httpRequest.cacheHit)
      "cache_lookup"       = EXTRACT(httpRequest.cacheLookup)
      "http_method"        = EXTRACT(httpRequest.requestMethod)
      "http_status"        = EXTRACT(httpRequest.status)
      "user_agent_client"  = REGEXP_EXTRACT(httpRequest.userAgent, "^([^/]+)")
      "user_agent_version" = REGEXP_EXTRACT(httpRequest.userAgent, "[^/]+/v?([^\\s]*)")
    }
  }
}
