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

module "shared" {
  source = "../shared"

  project_id                         = var.project_id
  dns_subdomain_name                 = var.dns_subdomain_name
  service_health_check_path          = var.service_health_check_path
  max_req_content_length             = var.max_req_content_length
  max_req_content_length_description = var.max_req_content_length_description
  enable_healthcheck_logging         = var.enable_healthcheck_logging
  http_grpc_qpm_rate_limit           = var.http_grpc_qpm_rate_limit
  enable_adaptive_protection         = var.enable_adaptive_protection
  create_grpc_health_check           = var.grpc_write_path == "" ? false : true
}

locals {
  hostname = trimsuffix("${var.dns_subdomain_name}.${var.dns_domain_name}", ".")
  prefix   = replace(var.dns_subdomain_name, ".", "-")
}

resource "google_dns_record_set" "A_tlog" {
  name = "${var.dns_subdomain_name}.${var.dns_domain_name}"
  type = "A"
  ttl  = 60

  project      = var.project_id
  managed_zone = var.dns_zone_name

  rrdatas = [google_compute_global_address.global_lb_ipv4.address]
}

resource "google_certificate_manager_dns_authorization" "tlog_auth" {
  name   = "${local.prefix}-dns-auth"
  domain = local.hostname
}

resource "google_dns_record_set" "CNAME_auth_tlog" {
  project      = var.project_id
  name         = google_certificate_manager_dns_authorization.tlog_auth.dns_resource_record[0].name
  type         = google_certificate_manager_dns_authorization.tlog_auth.dns_resource_record[0].type
  ttl          = 60
  managed_zone = var.dns_zone_name
  rrdatas      = [google_certificate_manager_dns_authorization.tlog_auth.dns_resource_record[0].data]
}

resource "google_compute_global_address" "global_lb_ipv4" {
  name         = "${local.prefix}-global-ext-lb"
  address_type = "EXTERNAL"
  project      = var.project_id
}

locals {
  http_neg_map = { for neg in var.active_http_negs : "${neg.name}-${neg.zone}" => neg }
  grpc_neg_map = { for neg in var.active_grpc_negs : "${neg.name}-${neg.zone}" => neg }
}

data "google_compute_network_endpoint_group" "k8s_http_neg" {
  for_each = local.http_neg_map

  name    = each.value.name
  project = var.project_id
  zone    = each.value.zone
}

data "google_compute_network_endpoint_group" "k8s_grpc_neg" {
  for_each = local.grpc_neg_map

  name    = each.value.name
  project = var.project_id
  zone    = each.value.zone
}

resource "google_compute_backend_service" "k8s_http_backend_service" {
  name    = "${local.prefix}-global-k8s-neg-backend-service"
  project = var.project_id

  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_name             = "http"
  protocol              = "HTTP"

  connection_draining_timeout_sec = 15
  health_checks                   = [module.shared.http_health_check_id]

  dynamic "backend" {
    for_each = data.google_compute_network_endpoint_group.k8s_http_neg
    iterator = neg

    content {
      group                 = neg.value.id
      balancing_mode        = "RATE"
      max_rate_per_endpoint = var.backend_service_max_rps
    }
  }

  security_policy = module.shared.security_policy_id

  log_config {
    enable = var.enable_backend_service_logging
  }
}

resource "google_compute_backend_service" "k8s_grpc_backend_service" {
  count   = var.grpc_write_path == "" ? 0 : 1
  name    = "${local.prefix}-global-k8s-grpc-neg-backend-service"
  project = var.project_id

  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_name             = "grpc"
  protocol              = "HTTP2"

  connection_draining_timeout_sec = 15
  health_checks                   = module.shared.grpc_health_check_id != "" ? [module.shared.grpc_health_check_id] : []

  dynamic "backend" {
    for_each = data.google_compute_network_endpoint_group.k8s_grpc_neg
    iterator = neg

    content {
      group                 = neg.value.id
      balancing_mode        = "RATE"
      max_rate_per_endpoint = var.backend_service_max_rps
    }
  }

  security_policy = module.shared.security_policy_id

  log_config {
    enable = var.enable_backend_service_logging
  }
}

resource "google_compute_url_map" "url_map" {
  name    = "${local.prefix}-global-lb"
  project = var.project_id

  default_service = google_compute_backend_service.k8s_http_backend_service.id

  host_rule {
    hosts        = [local.hostname]
    path_matcher = "global"
  }

  path_matcher {
    name            = "global"
    default_service = google_compute_backend_service.k8s_http_backend_service.id
    dynamic "route_rules" {
      for_each = length(var.active_http_negs) > 0 ? [1] : []

      content {
        priority = 1
        service  = google_compute_backend_service.k8s_http_backend_service.id
        match_rules {
          path_template_match = var.http_write_path
        }
        match_rules {
          full_path_match = "/healthz"
        }
      }
    }
    dynamic "route_rules" {
      for_each = length(var.active_grpc_negs) > 0 && var.grpc_write_path != "" ? [1] : []

      content {
        priority = 2
        service  = google_compute_backend_service.k8s_grpc_backend_service[0].id
        match_rules {
          path_template_match = var.grpc_write_path
        }
      }
    }
  }
}

resource "google_certificate_manager_certificate" "ssl_certificate" {
  name    = "${local.prefix}-global-ssl-cert"
  project = var.project_id

  managed {
    domains = [local.hostname]
    dns_authorizations = [
      google_certificate_manager_dns_authorization.tlog_auth.id
    ]
  }
}

resource "google_certificate_manager_certificate_map" "tlog_certificate_map" {
  name = "${local.prefix}-cert-map"
}

resource "google_certificate_manager_certificate_map_entry" "tlog_certificate_map_entry" {
  name         = "${local.prefix}-cert-map-entry"
  map          = google_certificate_manager_certificate_map.tlog_certificate_map.name
  certificates = [google_certificate_manager_certificate.ssl_certificate.id]
  hostname     = local.hostname
}

resource "google_compute_target_https_proxy" "lb_proxy" {
  name    = "${local.prefix}-global-https-proxy"
  project = var.project_id

  url_map = google_compute_url_map.url_map.id

  ssl_policy      = module.shared.ssl_policy_id
  certificate_map = "//certificatemanager.googleapis.com/${google_certificate_manager_certificate_map.tlog_certificate_map.id}"
}

resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  name    = "${local.prefix}-global-https-forwarding-rule"
  project = var.project_id

  ip_address            = google_compute_global_address.global_lb_ipv4.address
  target                = google_compute_target_https_proxy.lb_proxy.id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
