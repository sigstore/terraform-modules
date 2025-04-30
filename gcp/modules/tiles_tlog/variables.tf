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
  description = "name of DNS domain name in Google Cloud DNS"
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
