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

locals {
  prefix = replace(var.dns_subdomain_name, ".", "-")
}

resource "google_compute_health_check" "http_health_check" {
  count   = var.freeze_shard ? 0 : 1
  name    = var.http_health_check_name != "" ? var.http_health_check_name : "${local.prefix}-http-health-check"
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
  count   = var.freeze_shard || !var.create_grpc_health_check ? 0 : 1
  name    = var.grpc_health_check_name != "" ? var.grpc_health_check_name : "${local.prefix}-grpc-health-check"
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

resource "google_compute_security_policy" "k8s_http_grpc_security_policy" {
  count   = var.freeze_shard ? 0 : 1
  name    = var.security_policy_name != "" ? var.security_policy_name : "${local.prefix}-k8s-http-grpc-security-policy"
  project = var.project_id
  type    = "CLOUD_ARMOR"

  rule {
    action   = "deny(502)"
    priority = "1"

    match {
      expr {
        expression = "int(request.headers['content-length']) > ${var.max_req_content_length}"
      }
    }
    description = "Block all incoming write requests > ${var.max_req_content_length_description}"
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

resource "google_compute_security_policy" "bucket_security_policy" {
  name    = var.bucket_security_policy_name != "" ? var.bucket_security_policy_name : "${local.prefix}-bucket-security-policy"
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

resource "google_compute_ssl_policy" "ssl_policy" {
  name    = var.ssl_policy_name != "" ? var.ssl_policy_name : "${local.prefix}-ssl-policy"
  project = var.project_id

  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}
