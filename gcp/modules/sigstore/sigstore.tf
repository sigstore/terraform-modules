/**
 * Copyright 2022 The Sigstore Authors
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

// IAM project roles
module "project_roles" {
  count = length(var.iam_members_to_roles) > 0 ? 1 : 0

  source               = "../project_roles"
  project_id           = var.project_id
  iam_members_to_roles = var.iam_members_to_roles
}

// Private network
module "network" {
  source = "../network"

  region     = var.region
  project_id = var.project_id

  cluster_name = var.cluster_name

  depends_on = [
    module.project_roles
  ]
}

// Bastion
moved {
  from = module.bastion
  to   = module.bastion[0]
}
module "bastion" {
  source = "../bastion"

  count = var.enable_bastion ? 1 : 0

  project_id         = var.project_id
  region             = var.region
  zone               = var.bastion_zone
  network            = module.network.network_name
  subnetwork         = module.network.subnetwork_self_link
  tunnel_accessor_sa = var.tunnel_accessor_sa
  enable_oslogin     = var.bastion_enable_oslogin

  depends_on = [
    module.network,
    module.project_roles
  ]
}

moved {
  from = module.tuf
  to   = module.tuf[0]
}
module "tuf" {
  source = "../tuf"

  count = var.enable_tuf ? 1 : 0

  region     = var.tuf_region == "" ? var.region : var.tuf_region
  project_id = var.project_id

  tuf_bucket          = var.tuf_bucket
  tuf_bucket_member   = var.tuf_bucket_member
  gcs_logging_enabled = var.gcs_logging_enabled
  gcs_logging_bucket  = var.gcs_logging_bucket
  storage_class       = var.tuf_storage_class
  main_page_suffix    = var.tuf_main_page_suffix

  tuf_signer_service_account_name    = var.tuf_signer_service_account_name
  tuf_publisher_service_account_name = var.tuf_publisher_service_account_name

  tuf_keyring_name = var.tuf_keyring_name
  tuf_key_name     = var.tuf_key_name
  kms_location     = var.tuf_kms_location

  depends_on = [
    module.project_roles
  ]
}

// Monitoring
module "monitoring" {
  source = "../monitoring"

  // Disable module entirely if monitoring
  // is disabled
  count = var.monitoring.enabled ? 1 : 0

  project_id                       = var.project_id
  project_number                   = var.project_number
  cluster_location                 = module.gke-cluster.cluster_location
  cluster_name                     = var.cluster_name
  ca_pool_name                     = var.ca_pool_name
  fulcio_url                       = var.monitoring.fulcio_url
  rekor_url                        = var.monitoring.rekor_url
  timestamp_url                    = var.monitoring.timestamp_url
  dex_url                          = var.monitoring.dex_url
  tuf_url                          = var.monitoring.tuf_url
  ctlog_url                        = var.monitoring.ctlog_url
  notification_channel_ids         = var.monitoring.notification_channel_ids
  create_slos                      = var.create_slos
  timestamp_enabled                = var.monitoring.timestamp_enabled
  rekor_enabled                    = var.monitoring.rekor_enabled
  ctlog_enabled                    = var.monitoring.ctlog_enabled
  dex_enabled                      = var.monitoring.dex_enabled
  enable_k8s_cpu_utilization_alert = var.enable_k8s_cpu_utilization_alert
  uptime_check_period              = var.monitoring.uptime_check_period
  fulcio_check_uptime              = var.monitoring.fulcio_check_uptime
  timestamp_check_uptime           = var.monitoring.timestamp_check_uptime
  cloudsql_enabled                 = var.monitoring.cloudsql_enabled
  tuf_enabled                      = var.monitoring.tuf_enabled
  fulcio_create_logging_metrics    = var.monitoring.fulcio_create_logging_metrics
  timestamp_create_logging_metrics = var.monitoring.timestamp_create_logging_metrics

  depends_on = [
    module.gke-cluster,
    module.project_roles
  ]
}

resource "google_compute_firewall" "bastion-egress" {
  count = var.enable_bastion ? 1 : 0

  // Egress to Kubernetes API is the only allowed traffic
  name      = "bastion-egress"
  network   = module.network.network_name
  direction = "EGRESS"

  destination_ranges = ["${module.gke-cluster.cluster_endpoint}/32"]

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  target_tags = ["bastion"]

  depends_on = [
    module.network,
    module.gke-cluster,
    module.project_roles
  ]
}

# GKE cluster setup.
module "gke-cluster" {
  source = "../gke_cluster"

  region     = var.region
  project_id = var.project_id

  cluster_name           = var.cluster_name
  service_account_prefix = var.service_account_prefix

  network                       = module.network.network_self_link
  subnetwork                    = module.network.subnetwork_self_link
  cluster_secondary_range_name  = module.network.secondary_ip_range.0.range_name
  services_secondary_range_name = module.network.secondary_ip_range.1.range_name
  cluster_network_tag           = var.cluster_network_tag
  cluster_autoscaling_enabled   = var.cluster_autoscaling_enabled
  healthcheck_ports             = var.healthcheck_ports

  initial_node_count   = var.initial_node_count
  autoscaling_min_node = var.autoscaling_min_node
  autoscaling_max_node = var.autoscaling_max_node
  autoscaling_scope    = var.autoscaling_scope

  node_config_machine_type = var.gke_node_config_machine_type

  resource_limits_resource_cpu_max = var.gke_autoscaling_resource_limits_resource_cpu_max
  resource_limits_resource_mem_max = var.gke_autoscaling_resource_limits_resource_mem_max

  bastion_ip_address = var.enable_bastion ? module.bastion[0].ip_address : ""

  monitoring_components = var.cluster_monitoring_components

  security_group = var.gke_cluster_security_group

  oauth_scopes = var.gke_oauth_scopes

  enable_private_endpoint    = var.gke_use_ip_endpoint
  dns_control_plane_endpoint = var.gke_use_dns_endpoint

  depends_on = [
    module.network,
    module.bastion,
    module.project_roles
  ]
}

// MYSQL. This is the original DB that was used for both Rekor and CTLog.
// Newer versions of CTLog create their own database instance, so there's
// one database instance to a single ctlog shard.
moved {
  from = module.mysql
  to   = module.mysql[0]
}
module "mysql" {
  source = "../mysql"

  count = var.enable_mysql ? 1 : 0

  region     = var.region
  project_id = var.project_id

  cluster_name      = var.cluster_name
  database_version  = var.mysql_db_version
  tier              = var.mysql_rekor_tier
  availability_type = var.mysql_availability_type
  collation         = var.mysql_collation

  replica_zones = var.mysql_replica_zones
  replica_tier  = var.mysql_replica_tier

  network = module.network.network_self_link

  instance_name = var.mysql_instance_name
  db_name       = var.mysql_db_name

  ipv4_enabled                   = var.mysql_ipv4_enabled
  require_ssl                    = var.mysql_require_ssl
  backup_enabled                 = var.mysql_backup_enabled
  binary_log_backup_enabled      = var.mysql_binary_log_backup_enabled
  retained_backups               = var.mysql_retained_backups
  transaction_log_retention_days = var.mysql_transaction_log_retention_days
  deny_maintenance_period        = var.mysql_deny_maintenance_period
  final_backup_config            = var.mysql_final_backup_config
  maintenance_window             = var.mysql_maintenance_window

  breakglass_iam_group = var.breakglass_sql_iam_group

  database_flags = var.mysql_database_flags

  edition            = var.mysql_edition_rekor
  data_cache_enabled = var.mysql_data_cache_enabled_rekor

  depends_on = [
    module.network,
    module.gke-cluster,
    module.project_roles
  ]
}

moved {
  from = module.mysql[0].google_sql_database.searchindexes
  to   = module.rekor.google_sql_database.searchindexes
}

// Rekor
moved {
  from = module.rekor
  to   = module.rekor[0]
}
module "rekor" {
  source = "../rekor"

  count = var.enable_legacy_rekor ? 1 : 0

  region       = var.region
  project_id   = var.project_id
  cluster_name = var.cluster_name

  // KMS
  rekor_keyring_name = var.rekor_keyring_name
  rekor_key_name     = var.rekor_key_name
  kms_location       = "global"

  // Storage
  attestation_bucket  = var.attestation_bucket
  attestation_region  = var.attestation_region == "" ? var.region : var.attestation_region
  gcs_logging_enabled = var.gcs_logging_enabled
  gcs_logging_bucket  = var.gcs_logging_bucket
  storage_class       = var.attestation_storage_class

  dns_zone_name   = var.dns_zone_name
  dns_domain_name = var.dns_domain_name

  new_entry_pubsub_consumers = var.rekor_new_entry_pubsub_consumers

  index_database_instance_name = module.mysql[0].mysql_instance

  depends_on = [
    module.gke-cluster,
    module.project_roles
  ]
}

// Fulcio
module "fulcio" {
  source = "../fulcio"

  region                 = var.region
  project_id             = var.project_id
  cluster_name           = var.cluster_name
  service_account_prefix = var.service_account_prefix

  // Certificate authority
  ca_pool_name = var.ca_pool_name
  ca_name      = var.ca_name
  ca_type      = var.ca_type

  // KMS
  fulcio_keyring_name = var.fulcio_keyring_name
  fulcio_key_name     = var.fulcio_intermediate_key_name

  // DNS
  dns_zone_name   = var.dns_zone_name
  dns_domain_name = var.dns_domain_name

  // Policies
  cloud_armor_rules          = var.fulcio_cloud_armor_rules
  enable_adaptive_protection = var.fulcio_enable_adaptive_protection
  enable_cloud_armor         = var.fulcio_enable_cloud_armor
  enable_ssl_policy          = var.fulcio_enable_ssl_policy

  // Load balancing
  single_region       = var.single_region
  manage_dns_a_record = var.fulcio_manage_dns_a_record

  depends_on = [
    module.gke-cluster,
    module.network,
    module.project_roles
  ]
}

module "timestamp" {
  source = "../timestamp"

  region                 = var.region
  project_id             = var.project_id
  cluster_name           = var.cluster_name
  service_account_prefix = var.service_account_prefix

  // Disable module entirely if timestamp
  // is disabled
  count = var.timestamp.enabled ? 1 : 0

  // KMS
  timestamp_keyring_name        = var.timestamp_keyring_name
  timestamp_encryption_key_name = var.timestamp_encryption_key_name
  timestamp_ca_key_name         = var.timestamp_ca_key_name

  // DNS
  dns_zone_name   = var.dns_zone_name
  dns_domain_name = var.dns_domain_name

  // Policies
  cloud_armor_rules          = var.timestamp_cloud_armor_rules
  enable_adaptive_protection = var.timestamp_enable_adaptive_protection
  enable_cloud_armor         = var.timestamp_enable_cloud_armor
  enable_ssl_policy          = var.timestamp_enable_ssl_policy

  // Load balancing
  single_region       = var.single_region
  manage_dns_a_record = var.timestamp_manage_dns_a_record

  depends_on = [
    module.gke-cluster,
    module.network,
    module.project_roles
  ]
}

// Audit
module "audit" {
  count = var.enable_audit ? 1 : 0

  source     = "../audit"
  project_id = var.project_id
  log_types  = var.audit_log_types
}
moved {
  from = module.audit
  to   = module.audit[0]
}

// OSLogin configuration
module "oslogin" {
  source     = "../oslogin"
  project_id = var.project_id

  // Disable module entirely if oslogin is disabled
  count = var.oslogin.enabled ? 1 : 0

  oslogin = var.oslogin
}
moved {
  from = module.oslogin[0].google_compute_instance_iam_member.instance_oslogin_member
  to   = module.bastion[0].google_compute_instance_iam_member.instance_oslogin_member
}

// ctlog. This was the original (pre-ga) ctlog that shared the DB instance
// with Rekor.
moved {
  from = module.ctlog
  to   = module.ctlog[0]
}
module "ctlog" {
  source = "../ctlog"

  count = var.enable_legacy_ctlog ? 1 : 0

  project_id   = var.project_id
  cluster_name = var.cluster_name

  dns_zone_name   = var.dns_zone_name
  dns_domain_name = var.dns_domain_name

  depends_on = [
    module.gke-cluster,
    module.network,
    module.project_roles
  ]
}

// ctlog-shards. This will create CTLog shard that has its own Cloud SQL
// instance for each shard
module "ctlog_shards" {
  source = "../mysql-shard"

  for_each = var.ctlog_shards

  instance_name = each.value["instance_name"] != "" ? each.value["instance_name"] : format("%s-ctlog-%s", var.cluster_name, each.key)

  project_id = var.project_id
  region     = var.region

  cluster_name = var.cluster_name

  database_version = each.value["mysql_db_version"]
  tier             = each.value["mysql_tier"] != "" ? each.value["mysql_tier"] : var.mysql_tier

  replica_zones = var.mysql_replica_zones
  replica_tier  = var.mysql_replica_tier

  // We want to use consistent password across mysql DB instances, because
  // this is access only at the DB level and access to the DB instance is gated
  // by the IAM as well as private network.
  password = module.mysql[0].mysql_pass

  network = module.network.network_self_link

  db_name = var.ctlog_mysql_db_name

  availability_type              = var.mysql_availability_type
  ipv4_enabled                   = var.mysql_ipv4_enabled
  require_ssl                    = var.mysql_require_ssl
  backup_enabled                 = var.mysql_backup_enabled
  binary_log_backup_enabled      = var.mysql_binary_log_backup_enabled
  retained_backups               = var.mysql_retained_backups
  transaction_log_retention_days = var.mysql_transaction_log_retention_days
  collation                      = var.mysql_collation

  cloud_sql_iam_service_account = module.mysql[0].trillian_serviceaccount
  breakglass_iam_group          = var.breakglass_sql_iam_group

  database_flags = try(each.value["mysql_database_flags"], {})

  edition            = var.mysql_edition_ctlog
  data_cache_enabled = var.mysql_data_cache_enabled_ctlog

  depends_on = [
    module.gke-cluster,
    module.network,
    // Need to make sure we have the necessary network, service accounts, and
    // services.
    module.mysql
  ]
}

// standalone-mysql. This will create a MySQL database that is not part of
// something else. This is used to bring a database up with the appropriate
// permissions / connections so that it can be used then by manually wiring
// it to places where it's needed. This was initially created to bring up
// a different version of a database that we needed to migrate to.

module "standalone_mysqls" {
  source = "../mysql-shard"

  for_each = toset(var.standalone_mysqls)

  instance_name = format("%s-standalone-%s", var.cluster_name, each.key)

  project_id = var.project_id
  region     = var.region

  cluster_name = var.cluster_name
  // NB: This is commented out so that we pick up the defaults
  // for the particular environment consistently.
  //mysql_database_version  = var.mysql_db_version

  tier = var.standalone_mysql_tier

  replica_zones = var.mysql_replica_zones
  replica_tier  = var.mysql_replica_tier

  // We want to use consistent password across mysql DB instances, because
  // this is access only at the DB level and access to the DB instance is gated
  // by the IAM as well as private network.
  password = module.mysql[0].mysql_pass

  network = module.network.network_self_link

  db_name = var.mysql_db_name

  availability_type              = var.mysql_availability_type
  ipv4_enabled                   = var.mysql_ipv4_enabled
  require_ssl                    = var.standalone_mysql_ssl
  backup_enabled                 = var.mysql_backup_enabled
  binary_log_backup_enabled      = var.mysql_binary_log_backup_enabled
  retained_backups               = var.mysql_retained_backups
  transaction_log_retention_days = var.mysql_transaction_log_retention_days
  collation                      = var.mysql_collation

  cloud_sql_iam_service_account = module.mysql[0].trillian_serviceaccount
  breakglass_iam_group          = var.breakglass_sql_iam_group

  database_flags = var.mysql_database_flags

  depends_on = [
    module.gke-cluster,
    module.network,
    // Need to make sure we have the necessary network, service accounts, and
    // services.
    module.mysql
  ]
}

// dex
module "dex" {
  source = "../dex"

  count = var.enable_dex ? 1 : 0

  project_id = var.project_id

  cluster_name = var.cluster_name

  // DNS
  dns_zone_name   = var.dns_zone_name
  dns_domain_name = var.dns_domain_name

  // Policies
  cloud_armor_rules          = var.dex_cloud_armor_rules
  enable_adaptive_protection = var.dex_enable_adaptive_protection
  enable_cloud_armor         = var.dex_enable_cloud_armor
  enable_ssl_policy          = var.dex_enable_ssl_policy

  depends_on = [
    module.gke-cluster,
    module.network,
    module.project_roles
  ]
}

// Rekor Tiles Shards
module "rekor_tiles" {
  for_each = var.rekor_tiles_shards

  source = "../tiles_tlog"

  shard_name = each.key

  freeze_shard        = each.value.freeze_shard
  lb_backend_turndown = each.value.lb_backend_turndown

  project_id     = var.project_id
  project_number = var.project_number
  region         = var.region
  cluster_name   = var.cluster_name

  cluster_namespace_suffix = each.value.cluster_namespace_suffix
  cluster_service_account  = "rekor-tiles"

  bucket_name_suffix = each.value.bucket_name_suffix
  bucket_id_length   = each.value.bucket_id_length

  spanner_processing_units             = each.value.spanner_processing_units
  spanner_instance_name_suffix         = each.value.spanner_instance_name_suffix
  spanner_instance_display_name_suffix = each.value.spanner_instance_display_name_suffix

  keyring_name_suffix = each.value.keyring_name_suffix
  key_name            = each.value.key_name

  dns_zone_name      = var.dns_zone_name
  dns_domain_name    = var.dns_domain_name
  dns_subdomain_name = each.value.dns_subdomain_name

  http_grpc_qpm_rate_limit           = each.value.http_grpc_qpm_rate_limit
  max_req_content_length             = each.value.max_req_content_length
  max_req_content_length_description = each.value.max_req_content_length_description

  network_endpoint_group_http_name_suffix = each.value.network_endpoint_group_http_name_suffix
  network_endpoint_group_grpc_name_suffix = each.value.network_endpoint_group_grpc_name_suffix
  network_endpoint_group_zones            = each.value.network_endpoint_group_zones

  http_write_path        = "/api/v2/log/entries"
  grpc_write_path        = "/dev.sigstore.rekor.v2.Rekor/CreateEntry"
  http_read_path         = "/api/v2/{path=**}"
  http_read_rewrite_path = "/{path}"

  http_health_check_id      = var.rekor_http_health_check_id
  grpc_health_check_id      = var.rekor_grpc_health_check_id
  security_policy_id        = var.rekor_security_policy_id
  bucket_security_policy_id = var.rekor_bucket_security_policy_id
  ssl_policy_id             = var.rekor_ssl_policy_id

  spanner_timeseries_role_id = "SpannerMonitoringTimeseries"
  monitoring_role_id         = "OTelMetrics"

  spanner_database_sequencer_deletion_protection = each.value.spanner_database_sequencer_deletion_protection
  spanner_database_antispam_deletion_protection  = each.value.spanner_database_antispam_deletion_protection

  single_region = each.value.single_region

  depends_on = [
    module.gke-cluster,
    module.network,
    module.project_roles
  ]
}

module "rekor_monitoring" {
  for_each = {
    for k, v in var.rekor_tiles_shards : k => v
    if !v.freeze_shard && lookup(v, "enable_monitoring", true)
  }

  source = "../monitoring/rekorv2/active_shard"

  shard_name = each.key

  project_id           = var.project_id
  project_number       = var.project_number
  cluster_location     = var.region
  cluster_name         = var.cluster_name
  gke_namespace_suffix = each.value.cluster_namespace_suffix
  rekor_url            = each.value.rekor_url
  spanner_instance_id  = each.value.spanner_instance_id != null && each.value.spanner_instance_id != "" ? each.value.spanner_instance_id : module.rekor_tiles[each.key].spanner_instance_id

  notification_channel_ids = var.monitoring.notification_channel_ids
  create_slos              = var.create_slos
}

// CTLog Tiles Shards
module "ctlog_tiles" {
  for_each = var.ctlog_tiles_shards

  source = "../tiles_tlog"

  shard_name = each.key

  lb_backend_turndown = each.value.lb_backend_turndown
  freeze_shard        = each.value.freeze_shard

  project_id     = var.project_id
  project_number = var.project_number
  region         = var.region
  cluster_name   = var.cluster_name

  cluster_namespace_suffix = each.value.cluster_namespace_suffix
  cluster_service_account  = "ctlog-tiles"

  bucket_name_suffix = each.value.bucket_name_suffix
  bucket_id_length   = each.value.bucket_id_length

  spanner_processing_units             = each.value.spanner_processing_units
  spanner_instance_name_suffix         = each.value.spanner_instance_name_suffix
  spanner_instance_display_name_suffix = each.value.spanner_instance_display_name_suffix

  # TesseraCT uses Secret Manager instead of KMS
  keyring_name_suffix = ""
  enable_secrets      = true

  dns_zone_name      = var.dns_zone_name
  dns_domain_name    = var.dns_domain_name
  dns_subdomain_name = each.value.dns_subdomain_name

  http_grpc_qpm_rate_limit           = each.value.http_grpc_qpm_rate_limit
  max_req_content_length             = each.value.max_req_content_length
  max_req_content_length_description = each.value.max_req_content_length_description

  network_endpoint_group_http_name_suffix = each.value.network_endpoint_group_http_name_suffix
  network_endpoint_group_zones            = each.value.network_endpoint_group_zones

  http_write_path           = "/ct/v1/get-roots"
  http_read_path            = "/checkpoint"
  http_health_check_id      = var.ctlog_http_health_check_id
  security_policy_id        = var.ctlog_security_policy_id
  bucket_security_policy_id = var.ctlog_bucket_security_policy_id
  ssl_policy_id             = var.ctlog_ssl_policy_id

  spanner_timeseries_role_id = "SpannerMonitoringTimeseries"
  monitoring_role_id         = "OTelMetrics"

  spanner_database_sequencer_deletion_protection = each.value.spanner_database_sequencer_deletion_protection
  spanner_database_antispam_deletion_protection  = each.value.spanner_database_antispam_deletion_protection

  single_region = each.value.single_region

  depends_on = [
    module.gke-cluster,
    module.network,
    module.project_roles
  ]
}

module "ctlog_monitoring" {
  for_each = {
    for k, v in var.ctlog_tiles_shards : k => v
    if !v.freeze_shard && lookup(v, "enable_monitoring", true)
  }

  source = "../monitoring/tesseract/active_shard"

  shard_name = each.key

  project_id           = var.project_id
  project_number       = var.project_number
  cluster_location     = var.region
  cluster_name         = var.cluster_name
  gke_namespace_suffix = each.value.cluster_namespace_suffix
  ctlog_url            = each.value.ctlog_url
  spanner_instance_id  = each.value.spanner_instance_id != null && each.value.spanner_instance_id != "" ? each.value.spanner_instance_id : module.ctlog_tiles[each.key].spanner_instance_id

  notification_channel_ids = var.monitoring.notification_channel_ids
  create_slos              = var.create_slos
}

