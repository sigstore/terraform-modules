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

module "shared" {
  source = "./shared"
  count  = var.single_region ? 1 : 0

  project_id                         = var.project_id
  dns_subdomain_name                 = var.dns_subdomain_name
  service_health_check_path          = var.service_health_check_path
  max_req_content_length             = var.max_req_content_length
  max_req_content_length_description = var.max_req_content_length_description
  enable_healthcheck_logging         = var.enable_healthcheck_logging
  http_grpc_qpm_rate_limit           = var.http_grpc_qpm_rate_limit
  enable_adaptive_protection         = var.enable_adaptive_protection
  create_grpc_health_check           = var.network_endpoint_group_grpc_name_suffix != ""
  freeze_shard                       = var.freeze_shard

  http_health_check_name      = "${var.shard_name}-${var.dns_subdomain_name}-http-health-check"
  grpc_health_check_name      = "${var.shard_name}-${var.dns_subdomain_name}-grpc-health-check"
  security_policy_name        = "${var.shard_name}-${var.dns_subdomain_name}-k8s-http-grpc-security-policy"
  bucket_security_policy_name = "${var.shard_name}-${var.dns_subdomain_name}-bucket-security-policy"
  ssl_policy_name             = "${var.shard_name}-${var.dns_subdomain_name}-ssl-policy"
}
moved {
  from = google_compute_health_check.http_health_check
  to   = module.shared[0].google_compute_health_check.http_health_check
}
moved {
  from = google_compute_health_check.grpc_health_check
  to   = module.shared[0].google_compute_health_check.grpc_health_check
}
moved {
  from = google_compute_security_policy.k8s_http_grpc_security_policy_renamed
  to   = module.shared[0].google_compute_security_policy.k8s_http_grpc_security_policy_renamed
}
moved {
  from = google_compute_security_policy.bucket_security_policy_renamed
  to   = module.shared[0].google_compute_security_policy.bucket_security_policy_renamed
}
moved {
  from = google_compute_ssl_policy.ssl_policy
  to   = module.shared[0].google_compute_ssl_policy.ssl_policy
}

locals {
  http_health_check_id      = var.single_region && !var.freeze_shard ? module.shared[0].http_health_check_id : var.http_health_check_id
  grpc_health_check_id      = var.single_region && !var.freeze_shard && var.network_endpoint_group_grpc_name_suffix != "" ? module.shared[0].grpc_health_check_id : var.grpc_health_check_id
  security_policy_id        = var.single_region && !var.freeze_shard ? module.shared[0].security_policy_id : var.security_policy_id
  bucket_security_policy_id = var.single_region ? module.shared[0].bucket_security_policy_id : var.bucket_security_policy_id
  ssl_policy_id             = var.single_region ? module.shared[0].ssl_policy_id : var.ssl_policy_id
  hostname                  = trimsuffix("${var.shard_name}.${var.dns_subdomain_name}.${var.dns_domain_name}", ".")
  prefix                    = replace("${var.shard_name}-${var.dns_subdomain_name}", ".", "-")
}

resource "google_compute_global_address" "gce_lb_ipv4" {
  name         = "${local.prefix}-${var.cluster_name}-gce-ext-lb"
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

resource "google_compute_backend_service" "k8s_http_backend_service" {
  count   = var.freeze_shard ? 0 : 1
  name    = "${local.prefix}-k8s-neg-backend-service"
  project = var.project_id

  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_name             = "http"
  protocol              = "HTTP"

  connection_draining_timeout_sec = 15
  health_checks                   = [local.http_health_check_id]

  dynamic "backend" {
    for_each = data.google_compute_network_endpoint_group.k8s_http_neg
    iterator = neg

    content {
      group                 = neg.value.id
      balancing_mode        = "RATE"
      max_rate_per_endpoint = 5
    }
  }

  security_policy = local.security_policy_id

  log_config {
    enable = var.enable_backend_service_logging
  }
}

resource "google_compute_backend_service" "k8s_grpc_backend_service" {
  count   = var.freeze_shard || var.network_endpoint_group_grpc_name_suffix == "" ? 0 : 1
  name    = "${local.prefix}-k8s-grpc-neg-backend-service"
  project = var.project_id

  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_name             = "grpc"
  protocol              = "HTTP2"

  connection_draining_timeout_sec = 15
  health_checks                   = [local.grpc_health_check_id]

  dynamic "backend" {
    for_each = data.google_compute_network_endpoint_group.k8s_grpc_neg
    iterator = neg

    content {
      group                 = neg.value.id
      balancing_mode        = "RATE"
      max_rate_per_endpoint = 5
    }
  }

  security_policy = local.security_policy_id

  log_config {
    enable = var.enable_backend_service_logging
  }
}

resource "google_compute_backend_bucket" "tessera_backend_bucket" {
  name    = "${var.shard_name}-${var.bucket_name_suffix}"
  project = var.project_id

  depends_on = [google_storage_bucket.tessera_store]

  bucket_name = google_storage_bucket.tessera_store.name

  enable_cdn = var.enable_cdn
  cdn_policy {
    cache_mode = "USE_ORIGIN_HEADERS"
  }

  edge_security_policy = local.bucket_security_policy_id

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_url_map" "url_map" {
  name    = "${local.prefix}-lb"
  project = var.project_id

  default_service = google_compute_backend_bucket.tessera_backend_bucket.id

  host_rule {
    hosts        = var.dns_domain_name == "" ? ["*"] : [local.hostname]
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

resource "google_compute_managed_ssl_certificate" "ssl_certificate" {
  count   = var.dns_domain_name == "" ? 0 : 1 # Domain validation certificates can only be used if you have a registered domain name
  name    = "${local.prefix}-ssl-cert"
  project = var.project_id

  managed {
    domains = [local.hostname]
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_target_http_proxy" "lb_proxy" {
  count   = var.dns_domain_name == "" ? 1 : 0
  name    = "${local.prefix}-http-proxy"
  project = var.project_id

  url_map = google_compute_url_map.url_map.id

  lifecycle {
    prevent_destroy = true
  }
}
resource "google_compute_target_https_proxy" "lb_proxy" {
  count   = var.dns_domain_name == "" ? 0 : 1
  name    = "${local.prefix}-https-proxy"
  project = var.project_id

  url_map = google_compute_url_map.url_map.id

  ssl_certificates = [google_compute_managed_ssl_certificate.ssl_certificate[count.index].id]
  ssl_policy       = local.ssl_policy_id

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  count   = var.dns_domain_name == "" ? 1 : 0
  name    = "${local.prefix}-http-forwarding-rule"
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
  name    = "${local.prefix}-https-forwarding-rule"
  project = var.project_id

  ip_address            = google_compute_global_address.gce_lb_ipv4.address
  target                = google_compute_target_https_proxy.lb_proxy[count.index].id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  lifecycle {
    prevent_destroy = true
  }
}
