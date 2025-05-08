/**
 * Copyright 2025 The Sigstore Authors
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

variable "project_number" {
  type    = string
  default = ""
  validation {
    condition     = length(var.project_number) > 0
    error_message = "must specify project_number variable."
  }
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "cluster_name" {
  type    = string
  default = ""
}

variable "shard_name" {
  description = "name of the log shard"
  type        = string
}

variable "freeze_shard" {
  description = "whether the shard is frozen. Spanner instances will be scaled down."
  type        = bool
  default     = false
}

variable "spanner_instance_name_suffix" {
  description = "base name for transparency log resources"
  type        = string
}

variable "spanner_processing_units" {
  description = "number of Spanner processing units (increments of 100)"
  type        = number
  default     = 100
}

variable "spanner_instance_display_name_suffix" {
  description = "display name for the Spanner instance"
  type        = string
  default     = "tiles-tlog"
}

variable "spanner_instance_deletion_protection" {
  description = "whether to enable deletion protection for the spanner instance"
  type        = bool
  default     = true
}

variable "spanner_database_sequencer_deletion_protection" {
  description = "whether to enable deletion protection for the spanner sequencer database"
  type        = bool
  default     = true
}

variable "spanner_database_antispam_deletion_protection" {
  description = "whether to enable deletion protection for the spanner antispam database"
  type        = bool
  default     = true
}

variable "bucket_name_suffix" {
  description = "suffix of the bucket for Tessera tiles and checkpoints"
  type        = string
}

variable "storage_class" {
  description = "storage class for the Tessera bucket"
  type        = string
  default     = "STANDARD"
}

variable "public_bucket_member" {
  description = "user, group, or service account to grant access to the Tessera GCS bucket. Use 'allUsers' for general access, or e.g. group:mygroup@myorg.com for granular access."
  type        = string
  default     = "allUsers"
}

variable "keyring_name_suffix" {
  description = "suffix of the KMS keyring for the Tessera checkpoint signer"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "name of the KMS key for Tessera checkpoint signer"
  type        = string
  default     = "checkpoint-signer"
}

variable "kms_location" {
  description = "location of the KMS keyring for the Tessera checkpoint signer"
  type        = string
  default     = "global"
}

variable "kms_crypto_key_algorithm" {
  description = "signing algorithm"
  type        = string
}

variable "dns_zone_name" {
  description = "name of DNS Zone object in Google Cloud DNS"
  type        = string
}

variable "dns_domain_name" {
  description = "name of DNS domain name in Google Cloud DNS; set to '' in a development environment to avoid creating DNS records and associated TLS certificates"
  type        = string
}

variable "dns_subdomain_name" {
  description = "DNS subdomain name"
  type        = string
}

variable "cluster_namespace_suffix" {
  description = "suffix of the Kubernetes namespace for the transparency log deployment"
  type        = string
}

variable "cluster_service_account" {
  description = "kubernetes service account name for the transparency log deployment"
  type        = string
}

variable "network" {
  description = "VPC network in which the GKE cluster lives"
  type        = string
  default     = "default"
}

variable "http_service_port" {
  description = "internal HTTP port for the transparency log service pod"
  type        = string
  default     = "3000"
}

variable "grpc_service_port" {
  description = "internal gRPC port for the transparency log service pod"
  type        = string
  default     = "3001"
}

variable "service_health_check_path" {
  description = "HTTP URL request path for the service health check"
  type        = string
  default     = "/healthz"
}

variable "cluster_network_tag" {
  type        = string
  description = "GKE cluster network tag for firewall"
  default     = ""
}

variable "network_endpoint_group_http_name_suffix" {
  type        = string
  description = "suffix of the name of the network endpoint group that will be created for the HTTP service by the tiles Kubernetes service"
}

variable "network_endpoint_group_grpc_name_suffix" {
  type        = string
  description = "suffix of the name of the network endpoint group that will be created for the gRPC service by the tiles Kubernetes service"
}

variable "network_endpoint_group_zones" {
  type        = list(string)
  description = "zones where the NEGs live. NEGs will not exist until the Kubernetes service they belong to exists and creates them. This value must be set to empty if NEGs are not expected to exist yet, and then can later be updated."
  default     = []
}
