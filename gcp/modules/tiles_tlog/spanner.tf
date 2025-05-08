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

resource "google_spanner_instance" "tessera" {
  count            = var.freeze_shard ? 0 : 1
  project          = var.project_id
  name             = "${var.shard_name}-${var.spanner_instance_name_suffix}"
  config           = "regional-${var.region}"
  display_name     = "${var.shard_name}-${var.spanner_instance_display_name_suffix}"
  processing_units = var.spanner_processing_units

  depends_on = [google_project_service.service]
}

resource "google_spanner_database" "sequencer" {
  count    = var.freeze_shard ? 0 : 1
  project  = var.project_id
  name     = "sequencer"
  instance = google_spanner_instance.tessera[count.index].name

  deletion_protection = var.spanner_database_sequencer_deletion_protection

  depends_on = [google_spanner_instance.tessera]
}

resource "google_spanner_database" "antispam" {
  count    = var.freeze_shard ? 0 : 1
  project  = var.project_id
  name     = "sequencer-antispam"
  instance = google_spanner_instance.tessera[count.index].name

  deletion_protection = var.spanner_database_antispam_deletion_protection

  depends_on = [google_spanner_instance.tessera]
}

resource "google_spanner_instance_iam_member" "rekor_tiles_spanner_db_admin" {
  count      = var.freeze_shard ? 0 : 1
  project    = var.project_id
  instance   = google_spanner_instance.tessera[count.index].name
  role       = "roles/spanner.databaseAdmin"
  member     = local.workload_iam_member_id
  depends_on = [google_spanner_instance.tessera]
}
