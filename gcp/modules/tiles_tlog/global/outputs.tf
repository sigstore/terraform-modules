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
  value = module.shared.http_health_check_id
}

output "grpc_health_check_id" {
  value = module.shared.grpc_health_check_id
}

output "security_policy_id" {
  value = module.shared.security_policy_id
}

output "bucket_security_policy_id" {
  value = module.shared.bucket_security_policy_id
}

output "ssl_policy_id" {
  value = module.shared.ssl_policy_id
}
