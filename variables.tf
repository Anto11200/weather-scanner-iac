variable "google_client_id" {
  description = "Google OAuth Client ID"
  type        = string
}

variable "google_client_secret" {
  description = "Google OAuth Client Secret"
  type        = string
}

# AWS SNS
# variable "email_addresses" {
#   description = "List of email address for this subscription."
#   type        = list(string)
# }

# variable "enable_sns_sse_encryption" {
#   default     = true
#   description = "Enable Server-Side Encryption of the SNS Topic."
#   type        = bool
# }

# variable "sns_kms_master_key_id" {
#   default     = "alias/aws/sns"
#   description = "KMS Key ID for Server-Side Encryption of the SNS Topic."
#   type        = string
# }