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

output "rekor_http_health_check_id" {
  description = "The HTTP health check ID for the global Rekor LBs."
  value       = module.rekor_tiles_global.http_health_check_id
}

output "rekor_grpc_health_check_id" {
  description = "The gRPC health check ID for the global Rekor LBs."
  value       = module.rekor_tiles_global.grpc_health_check_id
}

output "rekor_security_policy_id" {
  description = "The security policy ID for the global Rekor LBs."
  value       = module.rekor_tiles_global.security_policy_id
}

output "rekor_bucket_security_policy_id" {
  description = "The bucket security policy ID for the global Rekor LBs."
  value       = module.rekor_tiles_global.bucket_security_policy_id
}

output "rekor_ssl_policy_id" {
  description = "The SSL policy ID for the global Rekor LBs."
  value       = module.rekor_tiles_global.ssl_policy_id
}

output "ctlog_http_health_check_id" {
  description = "The HTTP health check ID for the shared CTLog LBs."
  value       = module.ctlog_tiles_shared.http_health_check_id
}

output "ctlog_grpc_health_check_id" {
  description = "The gRPC health check ID for the shared CTLog LBs."
  value       = module.ctlog_tiles_shared.grpc_health_check_id
}

output "ctlog_security_policy_id" {
  description = "The security policy ID for the shared CTLog LBs."
  value       = module.ctlog_tiles_shared.security_policy_id
}

output "ctlog_bucket_security_policy_id" {
  description = "The bucket security policy ID for the shared CTLog LBs."
  value       = module.ctlog_tiles_shared.bucket_security_policy_id
}

output "ctlog_ssl_policy_id" {
  description = "The SSL policy ID for the shared CTLog LBs."
  value       = module.ctlog_tiles_shared.ssl_policy_id
}
