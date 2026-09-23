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
  type        = string
  description = "GCP Project ID."
  default     = ""
  validation {
    condition     = length(var.project_id) > 0
    error_message = "Must specify project_id variable."
  }
}

variable "tuf_bucket_name" {
  type        = string
  description = "The name of the GCS bucket storing the TUF repository."
}

variable "dns_zone_name" {
  type        = string
  description = "Name of DNS Zone object in Google Cloud DNS."
}

variable "dns_domain_name" {
  type        = string
  description = "Name of DNS domain name in Google Cloud DNS (e.g. 'sigstore.dev.')."
}

variable "dns_subdomain_name" {
  type        = string
  description = "Subdomain name for the TUF CDN endpoint, e.g. 'tuf-repo-cdn' or 'tuf.v2'."
}

variable "name_prefix" {
  type        = string
  description = "Prefix for GCP resource names (e.g. 'tuf' for v1, 'v2-tuf' for v2)."
  default     = "tuf"
}

variable "dns_ttl" {
  type        = number
  description = "TTL for DNS records."
  default     = 60
}
