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

output "http_health_check_id" {
  value = var.freeze_shard ? "" : google_compute_health_check.http_health_check[0].id
}

output "grpc_health_check_id" {
  value = var.freeze_shard || !var.create_grpc_health_check ? "" : google_compute_health_check.grpc_health_check[0].id
}

output "security_policy_id" {
  value = var.freeze_shard ? "" : google_compute_security_policy.k8s_http_grpc_security_policy[0].self_link
}

output "bucket_security_policy_id" {
  value = google_compute_security_policy.bucket_security_policy.self_link
}

output "ssl_policy_id" {
  value = google_compute_ssl_policy.ssl_policy.id
}
