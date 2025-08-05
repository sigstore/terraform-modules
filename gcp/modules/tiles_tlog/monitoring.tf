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

resource "google_project_iam_custom_role" "monitoring_metrics_descriptors" {
  project     = var.project_id
  role_id     = "OTelMetrics"
  title       = "OTel metrics management"
  description = "grant permissions on project for OTel metrics management"
  permissions = [
    "monitoring.metricDescriptors.create",
  ]
}

resource "google_project_iam_member" "tessera_metric_descriptors_creator" {
  count      = var.freeze_shard ? 0 : 1
  project    = var.project_id
  role       = "projects/${var.project_id}/roles/${google_project_iam_custom_role.monitoring_metrics_descriptors.role_id}"
  member     = local.workload_iam_member_id
  depends_on = [google_project_iam_custom_role.monitoring_metrics_descriptors]
}
