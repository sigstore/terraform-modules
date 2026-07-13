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

########################### PER-SERVICE ############################
# One per service globally, whether single region or multi-region. #
####################################################################

locals {
  hostname = trimsuffix("fulcio.${var.dns_domain_name}", ".")
}

resource "google_dns_record_set" "A_fulcio" {
  count = var.manage_dns_a_record ? 1 : 0

  name = "fulcio.${var.dns_domain_name}"
  type = "A"
  ttl  = 60

  project = var.project_id

  managed_zone = var.dns_zone_name
  rrdatas      = [google_compute_global_address.gce_lb_ipv4.address]
}

resource "google_certificate_manager_dns_authorization" "fulcio_auth" {
  count = var.single_region ? 0 : 1

  name   = "fulcio-dns-auth"
  domain = local.hostname
}

resource "google_dns_record_set" "CNAME_auth_fulcio" {
  count = var.single_region ? 0 : 1

  project = var.project_id

  name = google_certificate_manager_dns_authorization.fulcio_auth[count.index].dns_resource_record[0].name
  type = google_certificate_manager_dns_authorization.fulcio_auth[count.index].dns_resource_record[0].type
  ttl  = 60

  managed_zone = var.dns_zone_name
  rrdatas      = [google_certificate_manager_dns_authorization.fulcio_auth[count.index].dns_resource_record[0].data]
}

resource "google_compute_global_address" "gce_lb_ipv4" {
  name         = var.lb_address_name == "" ? format("fulcio-%s-gce-ext-lb", var.cluster_name) : var.lb_address_name
  address_type = "EXTERNAL"
  project      = var.project_id
}

resource "google_compute_security_policy" "http_security_policy" {
  count = var.enable_cloud_armor ? 1 : 0

  name    = var.cloud_armor_policy_name
  project = var.project_id
  type    = "CLOUD_ARMOR"

  dynamic "rule" {
    for_each = var.cloud_armor_rules
    content {
      action   = rule.value.action
      priority = rule.value.priority
      match {
        versioned_expr = rule.value.match.versioned_expr
        dynamic "config" {
          for_each = rule.value.match.config != null ? [rule.value.match.config] : []
          content {
            src_ip_ranges = config.value.src_ip_ranges
          }
        }
        dynamic "expr" {
          for_each = rule.value.match.expr != null ? [rule.value.match.expr] : []
          content {
            expression = expr.value.expression
          }
        }
      }

      dynamic "rate_limit_options" {
        for_each = rule.value.rate_limit_options != null ? [rule.value.rate_limit_options] : []
        content {
          enforce_on_key = rate_limit_options.value.enforce_on_key
          conform_action = rate_limit_options.value.conform_action
          exceed_action  = rate_limit_options.value.exceed_action
          rate_limit_threshold {
            count        = rate_limit_options.value.qpm_rate_limit
            interval_sec = rate_limit_options.value.interval_sec
          }
        }
      }

      dynamic "redirect_options" {
        for_each = rule.value.redirect_options != null ? [rule.value.redirect_options] : []
        content {
          type   = redirect_options.value.type
          target = redirect_options.value.target
        }
      }

      description = rule.value.description
    }

  }

  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "default rule"
  }

  advanced_options_config {
    json_parsing = "STANDARD"
  }

  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = var.enable_adaptive_protection
    }
  }
}

resource "google_compute_ssl_policy" "ssl_policy" {
  count = var.enable_ssl_policy ? 1 : 0

  name    = var.ssl_policy_name
  project = var.project_id

  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}

####################### PER-SERVICE MULTIREGION ########################
# One per service globally, only if using a multi-region configuration #
# rather than K8s-Ingress-driven load balancing.                       #
########################################################################

resource "google_compute_health_check" "http_health_check" {
  count = var.single_region ? 0 : 1

  name    = "fulcio-http-health-check"
  project = var.project_id

  timeout_sec         = 5
  check_interval_sec  = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    request_path       = "/healthz"
    port_specification = "USE_SERVING_PORT"
  }

  log_config {
    enable = var.enable_healthcheck_logging
  }
}

resource "google_compute_health_check" "grpc_health_check" {
  count = var.single_region ? 0 : 1

  name    = "fulcio-grpc-health-check"
  project = var.project_id

  timeout_sec         = 5
  check_interval_sec  = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  tcp_health_check {
    port_specification = "USE_SERVING_PORT"
  }

  log_config {
    enable = var.enable_healthcheck_logging
  }
}

data "google_compute_network_endpoint_group" "k8s_http_neg" {
  for_each = toset(var.network_endpoint_group_zones)

  name    = var.network_endpoint_group_name
  project = var.project_id
  zone    = each.key
}

data "google_compute_network_endpoint_group" "k8s_grpc_neg" {
  for_each = toset(var.network_endpoint_group_zones)

  name    = var.network_endpoint_group_name_grpc
  project = var.project_id
  zone    = each.key
}

resource "google_compute_backend_service" "http_backend_service" {
  count = var.single_region ? 0 : 1

  name    = "fulcio-http-backend"
  project = var.project_id

  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_name             = "http"
  protocol              = "HTTP"

  connection_draining_timeout_sec = 15
  health_checks                   = [google_compute_health_check.http_health_check[count.index].id]

  dynamic "backend" {
    for_each = data.google_compute_network_endpoint_group.k8s_http_neg
    iterator = neg
    content {
      group                 = neg.value.id
      balancing_mode        = "RATE"
      max_rate_per_endpoint = var.backend_service_max_rps
    }
  }

  depends_on      = [google_compute_security_policy.http_security_policy]
  security_policy = length(google_compute_security_policy.http_security_policy) > 0 ? google_compute_security_policy.http_security_policy[0].self_link : ""

  log_config {
    enable = var.enable_backend_service_logging
  }
}

resource "google_compute_backend_service" "grpc_backend_service" {
  count = var.single_region ? 0 : 1

  name    = "fulcio-grpc-backend"
  project = var.project_id

  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_name             = "grpc"
  protocol              = "HTTP2"

  connection_draining_timeout_sec = 15
  health_checks                   = [google_compute_health_check.grpc_health_check[count.index].id]

  dynamic "backend" {
    for_each = data.google_compute_network_endpoint_group.k8s_grpc_neg
    iterator = neg
    content {
      group                 = neg.value.id
      balancing_mode        = "RATE"
      max_rate_per_endpoint = var.backend_service_max_rps
    }
  }

  depends_on      = [google_compute_security_policy.http_security_policy]
  security_policy = length(google_compute_security_policy.http_security_policy) > 0 ? google_compute_security_policy.http_security_policy[0].self_link : ""

  log_config {
    enable = var.enable_backend_service_logging
  }
}

resource "google_compute_url_map" "url_map" {
  count = var.single_region ? 0 : 1

  name    = "fulcio-lb"
  project = var.project_id

  default_service = google_compute_backend_service.http_backend_service[count.index].id

  host_rule {
    hosts        = var.dns_domain_name == "" ? ["*"] : [local.hostname]
    path_matcher = "fulcio"
  }

  path_matcher {
    name            = "fulcio"
    default_service = google_compute_backend_service.http_backend_service[count.index].id
    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.http_backend_service[count.index].id
    }
    path_rule {
      paths   = ["/dev.sigstore.fulcio.v2.CA"]
      service = google_compute_backend_service.grpc_backend_service[count.index].id
    }
    path_rule {
      paths   = ["/dev.sigstore.fulcio.v2.CA/*"]
      service = google_compute_backend_service.grpc_backend_service[count.index].id
    }
  }
}

resource "google_certificate_manager_certificate" "ssl_certificate" {
  count = var.single_region ? 0 : 1

  name    = "fulcio-ssl-cert"
  project = var.project_id

  managed {
    domains = [local.hostname]
    dns_authorizations = [
      google_certificate_manager_dns_authorization.fulcio_auth[count.index].id
    ]
  }
}

resource "google_certificate_manager_certificate_map" "fulcio_certificate_map" {
  count = var.single_region ? 0 : 1

  name = "fulcio-cert-map"
}

resource "google_certificate_manager_certificate_map_entry" "fulcio_certificate_map_entry" {
  count = var.single_region ? 0 : 1

  name         = "fulcio-cert-map-entry"
  map          = google_certificate_manager_certificate_map.fulcio_certificate_map[count.index].name
  certificates = [google_certificate_manager_certificate.ssl_certificate[count.index].id]
  hostname     = local.hostname
}

resource "google_compute_target_https_proxy" "lb_proxy" {
  count = var.single_region ? 0 : 1

  name    = "fulcio-https-proxy"
  project = var.project_id

  url_map = google_compute_url_map.url_map[count.index].id

  ssl_policy      = google_compute_ssl_policy.ssl_policy[count.index].id
  certificate_map = "//certificatemanager.googleapis.com/${google_certificate_manager_certificate_map.fulcio_certificate_map[count.index].id}"
}

resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  count = var.single_region ? 0 : 1

  name    = "fulcio-https-forwarding-rule"
  project = var.project_id

  ip_address            = google_compute_global_address.gce_lb_ipv4.address
  target                = google_compute_target_https_proxy.lb_proxy[count.index].id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_protocol           = "TCP"
}
