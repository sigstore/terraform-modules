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

resource "google_monitoring_dashboard" "spanner_cpu_dashboard" {
  dashboard_json = <<EOF
{
  "displayName": "Spanner CPU Alerts",
  "mosaicLayout": {
    "columns": 48,
    "tiles": [
      {
        "height": 16,
        "width": 24,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.spanner_high_priority_cpu_utilization_warning.id}"
          }
        }
      },
      {
        "xPos": 24,
        "height": 16,
        "width": 24,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.spanner_smoothed_cpu_utilization_warning.id}"
          }
        }
      }
    ]
  }
}
EOF

  project = var.project_id

  depends_on = [
    google_monitoring_alert_policy.spanner_high_priority_cpu_utilization_warning,
    google_monitoring_alert_policy.spanner_smoothed_cpu_utilization_warning
  ]
}

resource "google_monitoring_dashboard" "timestamp_authority_dashboard" {
  project = var.project_id

  dashboard_json = file("${path.module}/timestamp_authority.json")
}

resource "google_monitoring_dashboard" "clients_dashboard" {
  project = var.project_id

  dashboard_json = file("${path.module}/clients.json")
}

resource "google_monitoring_dashboard" "rekor_v1" {
  project = var.project_id

  dashboard_json = file("${path.module}/rekor_v1.json")
}
