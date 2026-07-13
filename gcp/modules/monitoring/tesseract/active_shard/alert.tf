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

### Uptime alert

// Alert if we see a failure every minute for 5 consecutive minutes
resource "google_monitoring_alert_policy" "ctlog_uptime_alert" {
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
      filter          = format("metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" resource.type=\"uptime_url\" metric.label.\"check_id\"=\"%s\"", google_monitoring_uptime_check_config.uptime_ctlog.uptime_check_id)
      threshold_value = "1"

      trigger {
        count   = "1"
        percent = "0"
      }
    }

    display_name = "Failure of uptime check_id ctlog-uptime"
  }

  display_name          = "CT Log (TesseraCT) Uptime Alert - ${var.cluster_location}"
  enabled               = "true"
  notification_channels = local.notification_channels
  project               = var.project_id
  depends_on            = [google_monitoring_uptime_check_config.uptime_ctlog]
}

### K8s Alerts

resource "google_monitoring_alert_policy" "ctlog_k8s_pod_restart_failing_container" {
  # adding a dependency on the associated metric means that Terraform will 
  # always try to apply changes to the metric before this alert
  depends_on = [google_logging_metric.k8s_pod_restart_failing_container]

  # In the absence of data, incident will auto-close in 7 days
  alert_strategy {
    auto_close = "604800s"
  }

  combiner = "OR"

  conditions {
    condition_threshold {
      aggregations {
        alignment_period   = "600s"
        per_series_aligner = "ALIGN_COUNT"
      }

      comparison              = "COMPARISON_GT"
      duration                = "600s"
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"
      filter                  = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.k8s_pod_restart_failing_container.name}\" resource.type=\"k8s_pod\""
      threshold_value         = "1"

      trigger {
        count   = "1"
        percent = "0"
      }
    }

    display_name = "K8s Restart Failing Container for more than ten minutes"
  }

  display_name = "CT log (TesseraCT) ${var.shard_name} ${var.cluster_location} K8s Restart Failing Container"

  documentation {
    content   = "K8s is restarting a failing container for longer than the accepted time limit, please see playbook for help.\n"
    mime_type = "text/markdown"
  }

  enabled               = "true"
  notification_channels = local.notification_channels
  project               = var.project_id
}

resource "google_monitoring_alert_policy" "ctlog_k8s_pod_unschedulable" {
  # adding a dependency on the associated metric means that Terraform will 
  # always try to apply changes to the metric before this alert
  depends_on = [google_logging_metric.k8s_pod_unschedulable]

  # In the absence of data, incident will auto-close in 7 days
  alert_strategy {
    auto_close = "604800s"
  }

  combiner = "OR"

  conditions {
    condition_threshold {
      aggregations {
        alignment_period   = "600s"
        per_series_aligner = "ALIGN_COUNT"
      }

      comparison      = "COMPARISON_GT"
      duration        = "600s"
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.k8s_pod_unschedulable.name}\" resource.type=\"k8s_pod\""
      threshold_value = "1"

      trigger {
        count   = "1"
        percent = "0"
      }
    }

    display_name = "K8s was unable to schedule a pod for more than ten minutes"
  }

  display_name = "CT log (TesseraCT) ${var.shard_name} ${var.cluster_location} K8s Unschedulable"

  documentation {
    content   = "K8s was unable to schedule a pod for longer than the accepted time limit, please see playbook for help."
    mime_type = "text/markdown"
  }

  enabled               = "true"
  notification_channels = local.notification_channels
  project               = var.project_id
}

### Spanner Alerts

# Spanner High Priority CPU Utilization > 65% over 10 minutes
# (https://cloud.google.com/spanner/docs/monitoring-cloud#high-priority-cpu)
resource "google_monitoring_alert_policy" "spanner_high_priority_cpu_utilization_warning" {
  # In the absence of data, incident will auto-close in 7 days
  alert_strategy {
    auto_close = "604800s"
  }
  combiner = "OR"

  conditions {
    condition_threshold {
      aggregations {
        alignment_period     = "600s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_SUM"
      }
      comparison      = "COMPARISON_GT"
      duration        = "600s"
      filter          = "metric.type=\"spanner.googleapis.com/instance/cpu/utilization_by_priority\" resource.type=\"spanner_instance\" metric.labels.priority=\"high\" resource.labels.instance_id=\"${var.spanner_instance_id}\" resource.labels.location=\"${var.cluster_location}\""
      threshold_value = "0.65"
      trigger {
        count = "1"
      }
    }
    display_name = "Spanner Instance High Priority CPU Utilization > 65% (TesseraCT - ${var.cluster_location})"
  }
  display_name = "Spanner Instance High Priority CPU Utilization > 65% (TesseraCT - ${var.cluster_location})"
  documentation {
    content   = "Spanner instance high priority CPU utilization is >65%. Please reduce CPU utilization (https://cloud.google.com/spanner/docs/cpu-utilization#reduce)."
    mime_type = "text/markdown"
  }
  enabled               = "true"
  notification_channels = local.notification_channels
  project               = var.project_id

  user_labels = {
    severity = "warning"
  }
}

# Spanner 24 hour rolling average CPU utilization > 90%
resource "google_monitoring_alert_policy" "spanner_smoothed_cpu_utilization_warning" {
  # In the absence of data, incident will auto-close in 7 days
  alert_strategy {
    auto_close = "604800s"
  }
  combiner = "OR"

  conditions {
    condition_threshold {
      aggregations {
        alignment_period     = "600s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_SUM"
      }
      comparison      = "COMPARISON_GT"
      duration        = "600s"
      filter          = "metric.type=\"spanner.googleapis.com/instance/cpu/smoothed_utilization\" resource.type=\"spanner_instance\" resource.labels.instance_id=\"${var.spanner_instance_id}\" resource.labels.location=\"${var.cluster_location}\""
      threshold_value = "0.90"
      trigger {
        count = "1"
      }
    }
    display_name = "Spanner Instance 24 Hour Rolling Average CPU Utilization > 90% (Rekor v2 - ${var.cluster_location})"
  }
  display_name = "Spanner Instance 24 Hour Rolling Average CPU Utilization > 90% (Rekor v2 - ${var.cluster_location})"
  documentation {
    content   = "Spanner instance 24 hour rolling average CPU utilization is >90%. Please reduce CPU utilization (https://cloud.google.com/spanner/docs/cpu-utilization#reduce)."
    mime_type = "text/markdown"
  }
  enabled               = "true"
  notification_channels = local.notification_channels
  project               = var.project_id

  user_labels = {
    severity = "warning"
  }
}

# Spanner storage utilization > 80%
resource "google_monitoring_alert_policy" "spanner_disk_utilization_warning" {
  # In the absence of data, incident will auto-close in 7 days
  alert_strategy {
    auto_close = "604800s"
  }
  combiner = "OR"

  conditions {
    condition_threshold {
      aggregations {
        alignment_period     = "600s"
        per_series_aligner   = "ALIGN_MAX"
        cross_series_reducer = "REDUCE_SUM"
      }
      comparison      = "COMPARISON_GT"
      duration        = "0s"
      filter          = "metric.type=\"spanner.googleapis.com/instance/storage/utilization\" resource.type=\"spanner_instance\" resource.labels.instance_id=\"${var.spanner_instance_id}\" resource.labels.location=\"${var.cluster_location}\""
      threshold_value = "0.80"
      trigger {
        count = "1"
      }
    }
    display_name = "Spanner Instance Disk Usage > 80% (Rekor v2 - ${var.cluster_location})"
  }
  display_name = "Spanner Instance Disk Usage > 80% (Rekor v2 - ${var.cluster_location})"
  documentation {
    content   = "Spanner instance disk usage is reaching maximum capacity (https://cloud.google.com/spanner/docs/storage-utilization#reduce)."
    mime_type = "text/markdown"
  }
  enabled               = "true"
  notification_channels = local.notification_channels
  project               = var.project_id

  user_labels = {
    severity = "warning"
  }
}
