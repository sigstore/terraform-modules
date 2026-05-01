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

output "http_neg_name" {
  description = "Name of the HTTP Network Endpoint Group"
  value       = "${var.shard_name}-${var.network_endpoint_group_http_name_suffix}"
}

output "grpc_neg_name" {
  description = "Name of the gRPC Network Endpoint Group"
  value       = var.network_endpoint_group_grpc_name_suffix != "" ? "${var.shard_name}-${var.network_endpoint_group_grpc_name_suffix}" : ""
}
