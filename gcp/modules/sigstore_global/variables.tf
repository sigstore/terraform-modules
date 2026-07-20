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

variable "iam_members_to_roles" {
  description = "Map of IAM member (e.g. group:foo@sigstore.dev) to a set of IAM roles (e.g. roles/viewer)"
  type        = map(set(string))
  default     = {}
}

variable "dns_zone_name" {
  description = "Name of DNS Zone object in Google Cloud DNS"
  type        = string
}

variable "dns_domain_name" {
  description = "Name of DNS domain name in Google Cloud DNS"
  type        = string
}

variable "oslogin" {
  type = object({
    enabled          = optional(bool, false)
    enabled_with_2fa = optional(bool, false)
  })
  default = {
    enabled          = false
    enabled_with_2fa = false
  }
  description = "oslogin settings for access to VMs"
}

variable "enable_audit" {
  description = "Whether to enable auditing"
  type        = bool
  default     = true
}

variable "audit_log_types" {
  type        = list(string)
  description = "list of audit log types to apply against allServices"
  default     = ["ADMIN_READ", "DATA_READ", "DATA_WRITE"]
}

variable "enable_loadbalancer_logging" {
  description = "Whether to enable logging for the HTTP health checks and backend services for Fulcio, TSA, Dex"
  type        = bool
  default     = true
}

variable "network_endpoint_group_zones" {
  type        = list(string)
  description = "zones where the NEGs live. NEGs will not exist until the Kubernetes service they belong to exists and creates them. This value must be set to empty if NEGs are not expected to exist yet, and then can later be updated."
  default     = []
}

variable "timestamp_network_endpoint_group_name" {
  description = "Name of the NEG that will be created for the HTTP service by the timestamp Kubernetes service."
  type        = string
  default     = ""
}

variable "timestamp_backend_service_max_rps" {
  description = "Max requests per second that a single TSA backend instance can handle."
  type        = number
  default     = 100
}

variable "timestamp_cloud_armor_rules" {
  description = "Cloud Armor security policy rules for TSA."
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

variable "timestamp_manage_dns_a_record" {
  description = "Whether this module is in charge of managing the DNS A record for TSA. This is to enable transitioning from having DNS managed in a single region to managing the same record globally for all regions."
  type        = bool
  default     = true
}

variable "fulcio_network_endpoint_group_name" {
  description = "Name of the NEG that will be created for the HTTP service by the Fulcio Kubernetes service."
  type        = string
  default     = ""
}

variable "fulcio_network_endpoint_group_name_grpc" {
  description = "Name of the NEG that will be created for the gRPC service by the Fulcio Kubernetes service."
  type        = string
  default     = ""
}

variable "fulcio_backend_service_max_rps" {
  description = "Max requests per second that a single Fulcio backend instance can handle."
  type        = number
  default     = 100
}

variable "fulcio_cloud_armor_rules" {
  description = "Cloud Armor security policy rules for Fulcio."
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

variable "fulcio_manage_dns_a_record" {
  description = "Whether this module is in charge of managing the DNS A record for Fulcio. This is to enable transitioning from having DNS managed in a single region to managing the same record globally for all regions."
  type        = bool
  default     = true
}

variable "timestamp_uptime_check_period" {
  type    = string
  default = "60s"
}

variable "timestamp_url" {
  description = "Timestamp Authority URL"
  type        = string
  default     = "timestamp.sigstore.dev"
}

variable "fulcio_uptime_check_period" {
  type    = string
  default = "60s"
}

variable "fulcio_url" {
  description = "Fulcio URL"
  type        = string
  default     = "fulcio.sigstore.dev"
}

variable "notification_channel_ids" {
  description = "List of notification channel IDs which alerts should be sent to. You can find this by running `gcloud alpha monitoring channels list`."
  type        = list(string)
  default     = []
}

variable "rekor_tiles_http_negs" {
  type = list(object({
    name = string
    zone = string
  }))
  description = "List of objects containing the names and zones of active HTTP NEGs across all shards and regions to route write traffic to."
  default     = []
}

variable "rekor_tiles_grpc_negs" {
  type = list(object({
    name = string
    zone = string
  }))
  description = "List of objects containing the names and zones of active gRPC NEGs across all shards and regions to route write traffic to."
  default     = []
}

variable "rekor_tiles_dns_subdomain_name" {
  description = "DNS subdomain name for global Rekor"
  type        = string
  default     = "global.rekor"
}

variable "ctlog_tiles_dns_subdomain_name" {
  description = "DNS subdomain name for global CTLog"
  type        = string
  default     = "global.ctfe"
}

variable "project_number" {
  type    = string
  default = ""
}

variable "rekor_tiles_active_shards" {
  description = "List of active Rekor v2 shard names to monitor."
  type        = list(string)
  default     = []
}

variable "rekor_tiles_frozen_shards" {
  description = "List of frozen Rekor v2 shard names to monitor."
  type        = list(string)
  default     = []
}

variable "rekor_tiles_create_slos" {
  description = "True to enable Rekor tiles global LB SLO creation."
  type        = bool
  default     = true
}

variable "rekor_tiles_uptime_check_period" {
  description = "Uptime check period for the global Rekor tiles LB."
  type        = string
  default     = "60s"
}
