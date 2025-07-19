# --- OUTPUT RDS ---
output "rds_endpoint" {
  description = "L'endpoint dell'istanza RDS"
  value       = aws_db_instance.free_tier_rds.address
}

# --- OUTPUT EKS ---
output "eks_cluster_name" {
  description = "Nome del cluster EKS"
  value       = aws_eks_cluster.free_tier_eks.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint dell'API del cluster EKS"
  value       = aws_eks_cluster.free_tier_eks.endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "Dati dell'autorità di certificazione del cluster EKS (base64-encoded)"
  value       = aws_eks_cluster.free_tier_eks.certificate_authority[0].data
}

# --- OUTPUT SNS ---
output "sns_topic_arn" {
  description = "ARN del topic SNS per gli avvisi dell'applicazione"
  value       = aws_sns_topic.application_alerts.arn
}

# --- OUTPUT COGNITO ---
output "cognito_user_pool_id" {
  description = "ID del Cognito User Pool"
  value       = aws_cognito_user_pool.weather_scanner_user_pool.id
}

output "cognito_user_pool_client_id" {
  description = "ID del Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.weather_scanner_app_client.id
}

output "cognito_user_pool_domain_url" {
  description = "URL del dominio ospitato per l'interfaccia utente di Cognito"
  value       = "https://${aws_cognito_user_pool_domain.weather_scanner_domain.domain}.auth.${aws_cognito_user_pool.weather_scanner_user_pool.region}.amazoncognito.com"
}