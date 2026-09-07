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

output "directory_api_service_account_email" {
  description = "The email of the ArgoCD Directory API service account."
  value       = google_service_account.argocd-directory-api-sa.email
}

output "directory_api_service_account_unique_id" {
  description = "The unique numeric client ID of the ArgoCD Directory API service account (used for Google Workspace Domain-Wide Delegation)."
  value       = google_service_account.argocd-directory-api-sa.unique_id
}
