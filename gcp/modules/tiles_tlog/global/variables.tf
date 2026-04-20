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
    error_message = "Must specify project_id variable."
  }
}

variable "dns_zone_name" {
  description = "Name of DNS Zone object in Google Cloud DNS"
  type        = string
}

variable "dns_domain_name" {
  description = "Name of DNS domain name in Google Cloud DNS"
  type        = string
}

variable "dns_subdomain_name" {
  description = "Subdomain name for the service, e.g. 'v2.rekor' or 'tessera.ct'"
  type        = string
}

variable "active_http_negs" {
  type = list(object({
    name = string
    zone = string
  }))
  description = "List of objects containing the names and zones of active HTTP NEGs across all shards and regions to route write traffic to."
  default     = []
}

variable "active_grpc_negs" {
  type = list(object({
    name = string
    zone = string
  }))
  description = "List of objects containing the names and zones of active gRPC NEGs across all shards and regions to route write traffic to."
  default     = []
}

variable "backend_service_max_rps" {
  description = "Max requests per second that a single backend instance can handle."
  type        = number
  default     = 5
}

variable "enable_backend_service_logging" {
  description = "Whether to enable logging for the HTTP backend service."
  type        = bool
  default     = true
}

variable "http_write_path" {
  description = "The path for write requests on HTTP"
  type        = string
}

variable "grpc_write_path" {
  description = "The path for write requests on GRPC"
  type        = string
  default     = ""
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
