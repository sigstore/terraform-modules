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

resource "google_compute_global_address" "ext_ip" {
  project      = var.project_id
  name         = "${var.name_prefix}-repo-cdn-ext-ip"
  address_type = "EXTERNAL"
}

resource "google_compute_global_address" "ext_ipv6" {
  project      = var.project_id
  name         = "${var.name_prefix}-repo-cdn-ext-ipv6"
  address_type = "EXTERNAL"
  ip_version   = "IPV6"
}

resource "google_compute_managed_ssl_certificate" "cert" {
  project = var.project_id
  name    = "${var.name_prefix}-repo-cdn-ssl-cert"

  managed {
    domains = [local.hostname]
  }
}

// backend bucket with CDN policy with aggressive caching
resource "google_compute_backend_bucket" "cached" {
  project = var.project_id

  name        = "${var.name_prefix}-root-cached-backend-bucket"
  description = "Cached - ${var.name_prefix} TUF repository"
  bucket_name = var.tuf_bucket_name
  enable_cdn  = true
  cdn_policy {
    cache_mode        = "FORCE_CACHE_ALL"
    client_ttl        = 86400
    default_ttl       = 86400
    negative_caching  = false
    serve_while_stale = 0
  }
}

// backend bucket with no-cache CDN policy
resource "google_compute_backend_bucket" "not_cached" {
  project = var.project_id

  name        = "${var.name_prefix}-root-not-cached-backend-bucket"
  description = "Not cached - ${var.name_prefix} TUF repository"
  bucket_name = var.tuf_bucket_name
  enable_cdn  = false
}

// load balancer
resource "google_compute_url_map" "url_map" {
  project = var.project_id

  name            = "${var.name_prefix}-repo-cdn-lb"
  default_service = google_compute_backend_bucket.not_cached.id

  host_rule {
    hosts        = [local.hostname]
    path_matcher = "${var.name_prefix}-repo-cdn"
  }

  path_matcher {
    name            = "${var.name_prefix}-repo-cdn"
    default_service = google_compute_backend_bucket.cached.id

    path_rule {
      paths   = ["/timestamp.json", "/index.html", "/"]
      service = google_compute_backend_bucket.not_cached.id
    }
  }

  dynamic "test" {
    for_each = [
      "/timestamp.json",
      "/index.html",
      "/",
    ]
    content {
      service = google_compute_backend_bucket.not_cached.id
      host    = local.hostname
      path    = test.value
    }
  }

  dynamic "test" {
    for_each = [
      "/1.root.json",
      "/1.snapshot.json",
      "/1.targets.json",
    ]
    content {
      service = google_compute_backend_bucket.cached.id
      host    = local.hostname
      path    = test.value
    }
  }
}

resource "google_compute_ssl_policy" "ssl_policy" {
  project                   = var.project_id
  name                      = "${var.name_prefix}-repo-cdn-ingress-ssl-policy"
  profile                   = "MODERN"
  min_tls_version           = "TLS_1_2"
  post_quantum_key_exchange = "ENABLED"
}

resource "google_compute_target_https_proxy" "https_proxy" {
  project = var.project_id

  name             = "${var.name_prefix}-repo-cdn-https-proxy"
  url_map          = google_compute_url_map.url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.cert.id]
  ssl_policy       = google_compute_ssl_policy.ssl_policy.id
}

resource "google_compute_global_forwarding_rule" "fwd_rule_ipv4" {
  project = var.project_id

  name                  = "${var.name_prefix}-repo-cdn-https-fwd-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.https_proxy.id
  ip_address            = google_compute_global_address.ext_ip.id
}

resource "google_compute_global_forwarding_rule" "fwd_rule_ipv6" {
  project = var.project_id

  name                  = "${var.name_prefix}-repo-cdn-https-ipv6-fwd-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.https_proxy.id
  ip_address            = google_compute_global_address.ext_ipv6.id
}
