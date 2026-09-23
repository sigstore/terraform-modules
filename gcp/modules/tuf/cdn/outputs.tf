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

output "ext_ip_address" {
  value       = google_compute_global_address.ext_ip.address
  description = "TUF CDN external IPv4 address"
}

output "ext_ipv6_address" {
  value       = google_compute_global_address.ext_ipv6.address
  description = "TUF CDN external IPv6 address"
}

output "hostname" {
  value       = local.hostname
  description = "TUF CDN hostname"
}

output "ssl_certificate_id" {
  value       = google_compute_managed_ssl_certificate.cert.id
  description = "TUF CDN managed SSL certificate ID"
}

output "url_map_id" {
  value       = google_compute_url_map.url_map.id
  description = "TUF CDN URL map ID"
}

output "cached_backend_bucket_id" {
  value       = google_compute_backend_bucket.cached.id
  description = "TUF CDN cached backend bucket ID"
}

output "not_cached_backend_bucket_id" {
  value       = google_compute_backend_bucket.not_cached.id
  description = "TUF CDN not-cached backend bucket ID"
}

output "https_proxy_id" {
  value       = google_compute_target_https_proxy.https_proxy.id
  description = "TUF CDN target HTTPS proxy ID"
}

output "fwd_rule_ipv4_id" {
  value       = google_compute_global_forwarding_rule.fwd_rule_ipv4.id
  description = "TUF CDN IPv4 forwarding rule ID"
}

output "fwd_rule_ipv6_id" {
  value       = google_compute_global_forwarding_rule.fwd_rule_ipv6.id
  description = "TUF CDN IPv6 forwarding rule ID"
}

output "ssl_policy_id" {
  value       = google_compute_ssl_policy.ssl_policy.id
  description = "TUF CDN SSL policy ID"
}

