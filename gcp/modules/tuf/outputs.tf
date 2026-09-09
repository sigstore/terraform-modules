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

output "tuf_signer_service_account_email" {
  value       = google_service_account.tuf-signer-sa.email
  description = "TUF signer service account email"
}

output "tuf_publisher_service_account_email" {
  value       = google_service_account.tuf-publisher-sa.email
  description = "TUF publisher service account email"
}

output "tuf_bucket_name" {
  value       = google_storage_bucket.tuf.name
  description = "TUF bucket name"
}

output "tuf_keyring_name" {
  value       = google_kms_key_ring.tuf-keyring.name
  description = "TUF KMS keyring name"
}

output "tuf_keyring_id" {
  value       = google_kms_key_ring.tuf-keyring.id
  description = "TUF KMS keyring ID"
}

output "tuf_key_name" {
  value       = google_kms_crypto_key.tuf-key.name
  description = "TUF KMS key name"
}

output "tuf_key_id" {
  value       = google_kms_crypto_key.tuf-key.id
  description = "TUF KMS key ID"
}

output "tuf_key_version_id" {
  value       = google_kms_crypto_key_version.tuf-key-version.id
  description = "TUF KMS key version ID"
}
