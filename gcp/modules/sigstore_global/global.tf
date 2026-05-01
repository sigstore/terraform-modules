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

module "project_roles" {
  source               = "../project_roles"
  project_id           = var.project_id
  iam_members_to_roles = var.iam_members_to_roles
}

module "dex" {
  source = "../dex/global"

  project_id     = var.project_id
  project_number = var.project_number

  lb_address_name = "dex-global-ext-lb"

  dns_zone_name       = var.dns_zone_name
  dns_domain_name     = var.dns_domain_name
  manage_dns_a_record = var.dex_manage_dns_a_record

  enable_cloud_armor         = true
  cloud_armor_policy_name    = "dex-service-security-policy-global"
  cloud_armor_rules          = var.dex_cloud_armor_rules
  enable_adaptive_protection = true
  enable_ssl_policy          = true
  ssl_policy_name            = "dex-ingress-ssl-policy-global"

  network_endpoint_group_zones = var.network_endpoint_group_zones
  network_endpoint_group_name  = var.dex_network_endpoint_group_name
  backend_service_max_rps      = var.dex_backend_service_max_rps

  enable_healthcheck_logging     = var.enable_loadbalancer_logging
  enable_backend_service_logging = var.enable_loadbalancer_logging
}

module "timestamp" {
  source = "../timestamp/global"

  project_id = var.project_id

  lb_address_name = "timestamp-global-ext-lb"

  dns_zone_name       = var.dns_zone_name
  dns_domain_name     = var.dns_domain_name
  manage_dns_a_record = var.timestamp_manage_dns_a_record

  enable_cloud_armor         = true
  cloud_armor_policy_name    = "timestamp-service-security-policy-global"
  cloud_armor_rules          = var.timestamp_cloud_armor_rules
  enable_adaptive_protection = true
  enable_ssl_policy          = true
  ssl_policy_name            = "timestamp-ingress-ssl-policy-global"

  network_endpoint_group_zones = var.network_endpoint_group_zones
  network_endpoint_group_name  = var.timestamp_network_endpoint_group_name
  backend_service_max_rps      = var.timestamp_backend_service_max_rps

  enable_healthcheck_logging     = var.enable_loadbalancer_logging
  enable_backend_service_logging = var.enable_loadbalancer_logging
}

module "fulcio" {
  source = "../fulcio/global"

  project_id = var.project_id

  lb_address_name = "fulcio-global-ext-lb"

  dns_zone_name       = var.dns_zone_name
  dns_domain_name     = var.dns_domain_name
  manage_dns_a_record = var.fulcio_manage_dns_a_record

  enable_cloud_armor         = true
  cloud_armor_policy_name    = "fulcio-service-security-policy-global"
  cloud_armor_rules          = var.fulcio_cloud_armor_rules
  enable_adaptive_protection = true
  enable_ssl_policy          = true
  ssl_policy_name            = "fulcio-ingress-ssl-policy-global"

  network_endpoint_group_zones     = var.network_endpoint_group_zones
  network_endpoint_group_name      = var.fulcio_network_endpoint_group_name
  network_endpoint_group_name_grpc = var.fulcio_network_endpoint_group_name_grpc
  backend_service_max_rps          = var.fulcio_backend_service_max_rps

  enable_healthcheck_logging     = var.enable_loadbalancer_logging
  enable_backend_service_logging = var.enable_loadbalancer_logging
}
