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

resource "google_monitoring_dashboard" "tesseract_dashboard" {
  count   = var.create_slos ? 1 : 0
  project = var.project_id

  dashboard_json = templatefile("${path.module}/tesseract.json.tpl", {
    http_slo_id = module.slos[count.index].slo_ids["http-server-availability-pre-chain-post"]
  })
}
