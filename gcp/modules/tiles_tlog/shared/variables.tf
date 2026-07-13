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

variable "project_id" {
  type    = string
  default = ""
  validation {
    condition     = length(var.project_id) > 0
    error_message = "must specify project_id variable."
  }
}

variable "dns_subdomain_name" {
  description = "DNS subdomain name"
  type        = string
}

variable "service_health_check_path" {
  description = "HTTP URL request path for the service health check"
  type        = string
  default     = "/healthz"
}

variable "max_req_content_length" {
  description = "maximum request content length in bytes for the write path"
  type        = number
  default     = 8388608 // 8 MB
}

variable "max_req_content_length_description" {
  description = "maximum request content length, used only for security policy description"
  type        = string
  default     = "8MB"
}

variable "enable_healthcheck_logging" {
  description = "whether to enable logging for the HTTP and gRPC health checks"
  type        = bool
  default     = true
}

variable "http_grpc_qpm_rate_limit" {
  description = "count of write requests per minute allowed to HTTP and gRPC backends"
  type        = number
  default     = 600 // 10 QPS
}

variable "enable_adaptive_protection" {
  description = "whether to enable layer 7 DDoS adaptive protection"
  type        = bool
  default     = true
}

variable "create_grpc_health_check" {
  description = "whether to create the gRPC health check"
  type        = bool
  default     = true
}

variable "freeze_shard" {
  description = "whether the shard is frozen. Compute resources will be omitted."
  type        = bool
  default     = false
}

variable "http_health_check_name" {
  description = "name of the HTTP health check"
  type        = string
  default     = ""
}

variable "grpc_health_check_name" {
  description = "name of the gRPC health check"
  type        = string
  default     = ""
}

variable "security_policy_name" {
  description = "name of the backend service security policy"
  type        = string
  default     = ""
}

variable "bucket_security_policy_name" {
  description = "name of the bucket security policy"
  type        = string
  default     = ""
}

variable "ssl_policy_name" {
  description = "name of the SSL policy"
  type        = string
  default     = ""
}
