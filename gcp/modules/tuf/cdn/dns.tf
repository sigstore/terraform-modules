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
  hostname = trimsuffix("${var.dns_subdomain_name}.${var.dns_domain_name}", ".")
}

resource "google_dns_record_set" "a_record" {
  project = var.project_id
  name    = "${local.hostname}."
  type    = "A"
  ttl     = var.dns_ttl

  managed_zone = var.dns_zone_name

  rrdatas = [google_compute_global_address.ext_ip.address]

  // Do not publish the IPv4 address until the load balancer frontend exists.
  depends_on = [google_compute_global_forwarding_rule.fwd_rule_ipv4]
}

resource "google_dns_record_set" "aaaa_record" {
  project = var.project_id
  name    = "${local.hostname}."
  type    = "AAAA"
  ttl     = var.dns_ttl

  managed_zone = var.dns_zone_name

  rrdatas = [google_compute_global_address.ext_ipv6.address]

  // Do not publish the IPv6 address until the load balancer frontend exists.
  depends_on = [google_compute_global_forwarding_rule.fwd_rule_ipv6]
}
