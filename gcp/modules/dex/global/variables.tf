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

variable "project_number" {
  description = "The GCP project number."
  type        = string
  default     = ""
}

variable "single_region" {
  description = "Whether this module instance is only deployed in one region, and therefore in charge of managing its own IP address and DNS record but not other load balancer resources."
  type        = bool
  default     = false
}

variable "lb_address_name" {
  description = "Name of the global address of the load balancer. If not specified, defaults to 'oauth2-CLUSTER_NAME-gce-ext-lb'."
  type        = string
  default     = ""
}

variable "cluster_name" {
  type    = string
  default = ""
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

variable "enable_cloud_armor" {
  description = "Whether to create a Cloud Armor security policy."
  type        = bool
  default     = false
}

variable "cloud_armor_policy_name" {
  description = "Name of the Cloud Armor policy."
  type        = string
  default     = "dex-service-security-policy"
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

variable "ssl_policy_name" {
  description = "Name of the SSL policy."
  type        = string
  default     = "dex-ingress-ssl-policy"
}

variable "enable_healthcheck_logging" {
  description = "Whether to enable logging for the HTTP health check"
  type        = bool
  default     = true
}

variable "network_endpoint_group_zones" {
  type        = list(string)
  description = "zones where the NEGs live. NEGs will not exist until the Kubernetes service they belong to exists and creates them. This value must be set to empty if NEGs are not expected to exist yet, and then can later be updated."
  default     = []
}

variable "network_endpoint_group_name" {
  description = "Name of the NEG that will be created for the HTTP service by the Dex Kubernetes service."
  type        = string
  default     = ""
}

variable "backend_service_max_rps" {
  description = "Max requests per second that a single backend instance can handle."
  type        = number
  default     = 100
}

variable "enable_backend_service_logging" {
  description = "Whether to enable logging for the HTTP backend service."
  type        = bool
  default     = true
}
