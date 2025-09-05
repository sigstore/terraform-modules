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

resource "google_logging_metric" "client_user_agents" {
  project = var.project_id

  name        = "tuf/client_user_agents"
  description = "Tracks client applications and versions based on User-Agent headers in TUF requests."

  filter = "resource.type=\"http_load_balancer\" AND httpRequest.requestUrl=\"https://${var.tuf_url}/timestamp.json\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
    labels {
      key         = "version"
      value_type  = "STRING"
      description = "Version extracted from user agent string."
    }
    labels {
      key         = "client"
      value_type  = "STRING"
      description = "Application name extracted from user agent string."
    }
  }

  label_extractors = {
    "version" = <<-EOT
      REGEXP_EXTRACT(httpRequest.userAgent, "[^\/s]+[/ ]v?(\d+\.\d+(?:\.\d+)?)")
    EOT
    "client"  = <<-EOT
      REGEXP_EXTRACT(httpRequest.userAgent, "^([^\/\s]+)")
    EOT
  }
}
