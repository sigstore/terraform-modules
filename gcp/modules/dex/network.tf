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

resource "google_dns_record_set" "A_dex" {
  count = var.dns_domain_name == "" ? 0 : 1
  name  = "oauth2.${var.dns_domain_name}"
  type  = "A"
  ttl   = 60

  project      = var.project_id
  managed_zone = var.dns_zone_name

  rrdatas = [google_compute_global_address.gce_lb_ipv4.address]
}

// Create a static global IP for the external IPV4 GCE L7 load balancer
resource "google_compute_global_address" "gce_lb_ipv4" {
  name         = format("oauth2-%s-gce-ext-lb", var.cluster_name)
  address_type = "EXTERNAL"
  project      = var.project_id
}

resource "google_compute_security_policy" "http_security_policy" {
  count = var.enable_cloud_armor ? 1 : 0

  name    = "dex-service-security-policy"
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
  count   = var.enable_ssl_policy ? 1 : 0
  name    = "dex-ingress-ssl-policy"
  project = var.project_id

  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}
