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

resource "google_monitoring_uptime_check_config" "uptime_timestamp" {
  display_name = "Timestamp Authority Uptime"

  http_check {
    mask_headers   = "false"
    path           = "/api/v1/timestamp/certchain"
    port           = "443"
    request_method = "GET"
    use_ssl        = "true"
    validate_ssl   = "true"
  }

  monitored_resource {
    labels = {
      host       = var.timestamp_url
      project_id = var.project_id
    }

    type = "uptime_url"
  }

  period  = var.uptime_check_period
  project = var.project_id
  timeout = "10s"
}

// Alert if we see a failure every minute for 5 consecutive minutes
resource "google_monitoring_alert_policy" "timestamp_uptime_alerts" {
  # In the absence of data, incident will auto-close in 7 days
  alert_strategy {
    auto_close = "604800s"
  }
  combiner = "OR"

  conditions {
    condition_threshold {
      aggregations {
        alignment_period     = "60s"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields      = ["resource.*"]
        per_series_aligner   = "ALIGN_NEXT_OLDER"
      }

      comparison      = "COMPARISON_GT"
      duration        = "300s"
      filter          = format("metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" resource.type=\"uptime_url\" metric.label.\"check_id\"=\"%s\"", google_monitoring_uptime_check_config.uptime_timestamp.uptime_check_id)
      threshold_value = "1"

      trigger {
        count   = "1"
        percent = "0"
      }
    }

    display_name = "Failure of uptime check_id timestamp-uptime"
  }

  display_name          = "Timestamp Authority uptime alert"
  enabled               = "true"
  notification_channels = local.notification_channels
  project               = var.project_id
  depends_on            = [google_monitoring_uptime_check_config.uptime_timestamp]
}
