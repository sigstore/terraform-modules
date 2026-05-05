/**
 * Copyright 2022 The Sigstore Authors
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

variable "project_number" {
  description = "The GCP Project Number"
  type        = string
  default     = ""
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "single_region" {
  description = "Whether this module instance is only deployed in one region, and therefore in charge of managing its own IP address and DNS record but not other load balancer resources."
  type        = bool
  default     = true
}

variable "dns_zone_name" {
  description = "Name of DNS Zone object in Google Cloud DNS"
  type        = string
}

variable "dns_domain_name" {
  description = "Name of DNS domain name in Google Cloud DNS"
  type        = string
}

variable "manage_dns_a_record" {
  description = "Whether this module is in charge of managing the DNS A record. This is to enable transitioning from having DNS managed in a single region to managing the same record globally for all regions."
  type        = bool
  default     = true
}

variable "cluster_name" {
  type    = string
  default = ""
}

variable "cluster_namespace" {
  description = "Kubernetes namespace of the Dex deployment."
  type        = string
  default     = "default"
}

variable "cluster_service_account" {
  description = "Kubernetes service account name for the Dex deployment."
  type        = string
  default     = "default"
}

// Network
variable "enable_cloud_armor" {
  description = "Whether to create a Cloud Armor security policy."
  type        = bool
  default     = false
}

variable "cloud_armor_rules" {
  description = "Cloud Armor security policy rules."
  type = list(object({
    action      = string
    priority    = number
    description = optional(string)

    match = object({
      versioned_expr = optional(string)

      config = optional(object({
        src_ip_ranges = list(string)
      }))

      expr = optional(object({
        expression = string
      }))
    })

    rate_limit_options = optional(object({
      enforce_on_key = string
      conform_action = string
      exceed_action  = string
      qpm_rate_limit = number
      interval_sec   = number
    }))

    redirect_options = optional(object({
      type   = string
      target = string
    }))
  }))
  default = []
}

variable "enable_adaptive_protection" {
  description = "Whether to enable layer 7 DDoS adaptive protection in Cloud Armor."
  type        = bool
  default     = true
}

variable "enable_ssl_policy" {
  description = "Whether to create a SSL policy."
  type        = bool
  default     = false
}

variable "bucket_name" {
  description = "The name of the global bucket to attach IAM and Functions to."
  type        = string
  default     = ""
}
