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

resource "google_monitoring_alert_policy" "prober_rekorv2_endpoint_latency" {
  alert_strategy {
    auto_close = "604800s"
  }

  combiner = "OR"

  conditions {
    condition_threshold {
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_PERCENTILE_95"
        group_by_fields      = ["metric.label.endpoint"]
        per_series_aligner   = "ALIGN_MEAN"
      }

      comparison      = "COMPARISON_GT"
      duration        = "300s"
      filter          = format("resource.type = \"prometheus_target\" AND metric.type = \"prometheus.googleapis.com/api_endpoint_latency/summary\" AND metric.labels.host = \"%s\" AND %s", local.prober_url, "metric.labels.endpoint = \"/api/v2/log/entries\"")
      threshold_value = "10000"

      trigger {
        count   = "1"
        percent = "0"
      }
    }

    display_name = "API Prober: Rekor v2 API Endpoint Latency > 10 s"
  }

  display_name = "API Prober: Rekor v2 API Endpoint Latency > 10 s for 5 minutes"

  documentation {
    content   = "At least one supported Rekor v2 API Endpoint has had latency > 10 s for 5 minutes."
    mime_type = "text/markdown"
  }

  enabled               = "false"
  notification_channels = local.notification_channels
  project               = var.project_id
}

resource "google_monitoring_alert_policy" "prober_data_absent_alert" {
  alert_strategy {
    auto_close = "604800s"
  }

  combiner = "OR"

  conditions {
    condition_absent {
      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_PERCENTILE_95"
        group_by_fields      = ["metric.label.endpoint"]
        per_series_aligner   = "ALIGN_MEAN"
      }

      duration = "300s"
      filter   = format("resource.type = \"prometheus_target\" AND metric.type = \"prometheus.googleapis.com/api_endpoint_latency/summary\" AND metric.labels.host = \"%s\" AND %s", local.prober_url, "metric.labels.endpoint = \"/api/v2/log/entries\"")

      trigger {
        count   = "1"
        percent = "0"
      }
    }

    display_name = format("API Prober: Latency Data Absent for 5 minutes: %s", local.prober_url)
  }

  display_name = format("API Prober: Latency Data Absent for 5 minutes: %s", local.prober_url)

  documentation {
    content   = format("API Endpoint Latency Data Absent for 5 minutes: %s. Check playbook for more details.", local.prober_url)
    mime_type = "text/markdown"
  }

  enabled               = "true"
  notification_channels = local.notification_channels
  project               = var.project_id
}
