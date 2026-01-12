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

locals {
  cluster_network_tag = var.cluster_network_tag != "" ? var.cluster_network_tag : "gke-${var.cluster_name}"
}

resource "google_compute_global_address" "gce_lb_ipv4" {
  name         = "${var.shard_name}-${var.dns_subdomain_name}-${var.cluster_name}-gce-ext-lb"
  address_type = "EXTERNAL"
  project      = var.project_id

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_dns_record_set" "A_tlog" {
  count = var.dns_domain_name == "" ? 0 : 1

  name = "${var.shard_name}.${var.dns_subdomain_name}.${var.dns_domain_name}"
  type = "A"
  ttl  = 60

  project      = var.project_id
  managed_zone = var.dns_zone_name

  rrdatas = [google_compute_global_address.gce_lb_ipv4.address]

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_firewall" "backend_service_health_check" {
  count   = var.freeze_shard ? 0 : 1
  name    = "${var.shard_name}-${var.dns_subdomain_name}-fw-allow-health-check-and-proxy"
  project = var.project_id

  network       = var.network
  direction     = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = [local.cluster_network_tag]
  allow {
    protocol = "tcp"
    ports    = var.network_endpoint_group_grpc_name_suffix == "" ? [var.http_service_port] : [var.http_service_port, var.grpc_service_port]
  }
}

resource "google_compute_health_check" "http_health_check" {
  count   = var.freeze_shard ? 0 : 1
  name    = "${var.shard_name}-${var.dns_subdomain_name}-http-health-check"
  project = var.project_id

  timeout_sec         = 5
  check_interval_sec  = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    request_path       = var.service_health_check_path
    port_specification = "USE_SERVING_PORT"
  }

  log_config {
    enable = var.enable_healthcheck_logging
  }
}

resource "google_compute_health_check" "grpc_health_check" {
  count   = var.freeze_shard || var.network_endpoint_group_grpc_name_suffix == "" ? 0 : 1
  name    = "${var.shard_name}-${var.dns_subdomain_name}-grpc-health-check"
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
  for_each = var.freeze_shard ? [] : toset(var.network_endpoint_group_zones)

  name    = "${var.shard_name}-${var.network_endpoint_group_http_name_suffix}"
  project = var.project_id
  zone    = each.key
}

data "google_compute_network_endpoint_group" "k8s_grpc_neg" {
  for_each = var.freeze_shard || var.network_endpoint_group_grpc_name_suffix == "" ? [] : toset(var.network_endpoint_group_zones)

  name    = "${var.shard_name}-${var.network_endpoint_group_grpc_name_suffix}"
  project = var.project_id
  zone    = each.key
}

// TODO: delete this resource
resource "google_compute_security_policy" "k8s_http_grpc_security_policy" {
  count   = var.freeze_shard ? 0 : 1
  name    = "${var.shard_name}-k8s-http-grpc-security-policy"
  project = var.project_id
  type    = "CLOUD_ARMOR"

  rule {
    action   = "deny(502)"
    priority = "1"

    match {
      expr {
        expression = "int(request.headers['content-length']) > 8388608"
      }
    }
    description = "Block all incoming write requests > 8MB"
  }

  rule {
    action   = "throttle"
    priority = "10"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      enforce_on_key = "IP"
      conform_action = "allow"
      exceed_action  = "deny(429)"
      rate_limit_threshold {
        count        = var.http_grpc_qpm_rate_limit
        interval_sec = "60"
      }
    }
    description = "Rate limit all HTTP write traffic by client IP"
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
    json_custom_config {
      content_types = ["application/json"]
    }
  }

  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = var.enable_adaptive_protection
    }
  }
}

resource "google_compute_security_policy" "k8s_http_grpc_security_policy_renamed" {
  count   = var.freeze_shard ? 0 : 1
  name    = "${var.shard_name}-${var.dns_subdomain_name}-k8s-http-grpc-security-policy"
  project = var.project_id
  type    = "CLOUD_ARMOR"

  rule {
    action   = "deny(502)"
    priority = "1"

    match {
      expr {
        expression = "int(request.headers['content-length']) > 8388608"
      }
    }
    description = "Block all incoming write requests > 8MB"
  }

  rule {
    action   = "throttle"
    priority = "10"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      enforce_on_key = "IP"
      conform_action = "allow"
      exceed_action  = "deny(429)"
      rate_limit_threshold {
        count        = var.http_grpc_qpm_rate_limit
        interval_sec = "60"
      }
    }
    description = "Rate limit all HTTP write traffic by client IP"
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
    json_custom_config {
      content_types = ["application/json"]
    }
  }

  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = var.enable_adaptive_protection
    }
  }
}

resource "google_compute_backend_service" "k8s_http_backend_service" {
  count   = var.freeze_shard ? 0 : 1
  name    = "${var.shard_name}-${var.dns_subdomain_name}-k8s-neg-backend-service"
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
      max_rate_per_endpoint = 5
    }
  }

  depends_on = [google_compute_security_policy.k8s_http_grpc_security_policy[0]]

  security_policy = google_compute_security_policy.k8s_http_grpc_security_policy[0].self_link

  log_config {
    enable = var.enable_backend_service_logging
  }
}

resource "google_compute_backend_service" "k8s_grpc_backend_service" {
  count   = var.freeze_shard || var.network_endpoint_group_grpc_name_suffix == "" ? 0 : 1
  name    = "${var.shard_name}-${var.dns_subdomain_name}-k8s-grpc-neg-backend-service"
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
      max_rate_per_endpoint = 5
    }
  }

  depends_on = [google_compute_security_policy.k8s_http_grpc_security_policy[0]]

  security_policy = google_compute_security_policy.k8s_http_grpc_security_policy[0].self_link

  log_config {
    enable = var.enable_backend_service_logging
  }
}

// TODO: delete this resource
resource "google_compute_security_policy" "bucket_security_policy" {
  name    = "${var.shard_name}-bucket-security-policy"
  project = var.project_id
  type    = "CLOUD_ARMOR_EDGE"

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
}

resource "google_compute_backend_bucket" "tessera_backend_bucket" {
  name    = "${var.shard_name}-${var.bucket_name_suffix}"
  project = var.project_id

  depends_on = [google_storage_bucket.tessera_store, google_compute_security_policy.bucket_security_policy]

  bucket_name = google_storage_bucket.tessera_store.name

  enable_cdn = var.enable_cdn
  cdn_policy {
    cache_mode = "USE_ORIGIN_HEADERS"
  }

  edge_security_policy = google_compute_security_policy.bucket_security_policy.self_link

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_security_policy" "bucket_security_policy_renamed" {
  name    = "${var.shard_name}-${var.dns_subdomain_name}-bucket-security-policy"
  project = var.project_id
  type    = "CLOUD_ARMOR_EDGE"

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
}

locals {
  hostname = var.dns_domain_name == "" ? "*" : trimsuffix("${var.shard_name}.${var.dns_subdomain_name}.${var.dns_domain_name}", ".")
}

resource "google_compute_url_map" "url_map" {
  name    = "${var.shard_name}-${var.dns_subdomain_name}-lb"
  project = var.project_id

  default_service = google_compute_backend_bucket.tessera_backend_bucket.id

  host_rule {
    hosts        = [local.hostname]
    path_matcher = var.shard_name
  }

  path_matcher {
    name            = var.shard_name
    default_service = google_compute_backend_bucket.tessera_backend_bucket.id
    dynamic "route_rules" {
      for_each = var.lb_backend_turndown ? [] : [1]

      content {
        priority = 1
        service  = google_compute_backend_service.k8s_http_backend_service[0].id
        match_rules {
          path_template_match = var.http_write_path
        }
        match_rules {
          full_path_match = "/healthz"
        }
      }
    }
    dynamic "route_rules" {
      for_each = var.lb_backend_turndown || var.grpc_write_path == "" ? [] : [1]

      content {
        priority = 2
        service  = google_compute_backend_service.k8s_grpc_backend_service[0].id
        match_rules {
          path_template_match = var.grpc_write_path
        }
      }
    }
    route_rules {
      priority = 3
      service  = google_compute_backend_bucket.tessera_backend_bucket.id
      match_rules {
        path_template_match = var.http_read_path
      }
      dynamic "route_action" {
        for_each = var.http_read_rewrite_path == "" ? [] : [1]
        content {
          url_rewrite {
            path_template_rewrite = var.http_read_rewrite_path
          }
        }
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

// Create HTTPS certificate and load balancer configuration if managing DNS, otherwise use HTTP.
// Production instances should ALWAYS set a domain name and use HTTPS. Developers may choose to use HTTP for simpler ephemeral deployments.

resource "google_compute_ssl_policy" "ssl_policy" {
  name    = "${var.shard_name}-${var.dns_subdomain_name}-ssl-policy"
  project = var.project_id

  profile         = "MODERN"
  min_tls_version = "TLS_1_2"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_managed_ssl_certificate" "ssl_certificate" {
  count   = var.dns_domain_name == "" ? 0 : 1 # Domain validation certificates can only be used if you have a registered domain name
  name    = "${var.shard_name}-${var.dns_subdomain_name}-ssl-cert"
  project = var.project_id

  managed {
    domains = ["${var.shard_name}.${var.dns_subdomain_name}.${var.dns_domain_name}"]
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_target_http_proxy" "lb_proxy" {
  count   = var.dns_domain_name == "" ? 1 : 0
  name    = "${var.shard_name}-${var.dns_subdomain_name}-http-proxy"
  project = var.project_id

  url_map = google_compute_url_map.url_map.id

  lifecycle {
    prevent_destroy = true
  }
}
resource "google_compute_target_https_proxy" "lb_proxy" {
  count   = var.dns_domain_name == "" ? 0 : 1
  name    = "${var.shard_name}-${var.dns_subdomain_name}-https-proxy"
  project = var.project_id

  url_map = google_compute_url_map.url_map.id

  ssl_certificates = [google_compute_managed_ssl_certificate.ssl_certificate[count.index].id]
  ssl_policy       = google_compute_ssl_policy.ssl_policy.id

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  count   = var.dns_domain_name == "" ? 1 : 0
  name    = "${var.shard_name}-${var.dns_subdomain_name}-http-forwarding-rule"
  project = var.project_id

  ip_address            = google_compute_global_address.gce_lb_ipv4.address
  target                = google_compute_target_http_proxy.lb_proxy[count.index].id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  count   = var.dns_domain_name == "" ? 0 : 1
  name    = "${var.shard_name}-${var.dns_subdomain_name}-https-forwarding-rule"
  project = var.project_id

  ip_address            = google_compute_global_address.gce_lb_ipv4.address
  target                = google_compute_target_https_proxy.lb_proxy[count.index].id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  lifecycle {
    prevent_destroy = true
  }
}
