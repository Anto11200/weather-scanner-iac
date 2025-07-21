#########################
#                       #
#      OUTPUT RDS       #
#                       #
#########################
output "rds_endpoint" {
  description = "L'endpoint dell'istanza RDS"
  value       = aws_db_instance.free_tier_rds.address
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

#########################
#                       #
#      OUTPUT EKS       #
#                       #
#########################
output "eks_cluster_id" {
  description = "ID del cluster EKS"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "Endpoint API server EKS"
  value       = module.eks.cluster_endpoint
}

output "eks_oidc_issuer" {
  description = "Issuer URL per IRSA"
  value       = module.eks.cluster_oidc_issuer_url
}

output "eks_node_security_group" {
  description = "Security Group dei nodi EKS"
  value       = module.eks.node_security_group_id
}