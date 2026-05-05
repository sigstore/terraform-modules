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

resource "google_monitoring_alert_policy" "function_errors" {
  project = var.project_id

  display_name = "Dex JWKS Merger - Execution Errors"
  combiner     = "OR"

  conditions {
    display_name = "Function execution failed"

    condition_threshold {
      # Monitor the execution count of Gen 2 Cloud Functions
      filter     = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"dex-jwks-merger\" AND metric.type = \"run.googleapis.com/request_count\" AND metric.labels.response_code_class != \"2xx\""
      duration   = "0s" # Trigger immediately on the first failure
      comparison = "COMPARISON_GT"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [local.notification_channels]

  documentation {
    content   = "The Dex JWKS Cloud Function is throwing errors. Check the Cloud Run logs for 'dex-jwks-merger' immediately to see the Go panic/error trace."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "pipeline_stagnation" {
  project = var.project_id

  display_name = "Dex JWKS Merger - Pipeline Stalled"
  combiner     = "OR"

  conditions {
    display_name = "No successful merges in 1 hour"

    condition_absent {
      # Look for successful (2xx) executions of the function
      filter = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"dex-jwks-merger\" AND metric.type = \"run.googleapis.com/request_count\" AND metric.labels.response_code_class = \"2xx\""

      # If this metric is completely missing for 3600 seconds (1 hour), trigger the alert.
      duration = "3600s"

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [local.notification_channels]

  documentation {
    content   = "CRITICAL: The Dex JWKS Cloud Function has not successfully merged keys in over an hour. \n\n1. Check the K8s CronJob logs in the 'dex-system' namespace. \n2. Check if the 'keys/' directory in GCS is receiving new files. \n3. Check the Cloud Function logs for silent failures. \n\nFulcio will eventually start rejecting tokens if this is not resolved."
    mime_type = "text/markdown"
  }
}
