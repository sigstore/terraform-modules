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

resource "google_kms_key_ring" "keyring" {
  // Keyrings cannot be deleted, so the keyring resource will remain when the shard is frozen
  count      = var.keyring_name_suffix == "" ? 0 : 1
  project    = var.project_id
  name       = "${var.shard_name}-${var.keyring_name_suffix}"
  location   = var.kms_location
  depends_on = [google_project_service.service]
}

resource "google_kms_crypto_key" "key_encryption_key" {
  // Deleting the key will destroy all key versions, but the key resource will remain when the shard is frozen
  count    = var.keyring_name_suffix == "" || var.freeze_shard ? 0 : 1
  name     = var.key_name
  key_ring = google_kms_key_ring.keyring[count.index].id
  version_template {
    algorithm        = var.kms_crypto_key_algorithm
    protection_level = "SOFTWARE"
  }
  depends_on = [google_kms_key_ring.keyring]
}

resource "google_project_iam_member" "decrypter" {
  // Only needed if using KMS signer or when shard is active
  count   = var.keyring_name_suffix == "" || var.freeze_shard ? 0 : 1
  project = var.project_id
  role    = "roles/cloudkms.cryptoKeyDecrypter"
  member  = local.workload_iam_member_id
}

resource "google_project_iam_member" "kms_member" {
  // Only needed if using KMS signer or when shard is active
  count   = var.keyring_name_suffix == "" || var.freeze_shard ? 0 : 1
  project = var.project_id
  role    = "roles/cloudkms.viewer"
  member  = local.workload_iam_member_id
}
