#########################
#                       #
#      OUTPUT RDS       #
#                       #
#########################
# output "rds_endpoint" {
#   description = "L'endpoint dell'istanza RDS"
#   value       = aws_db_instance.free_tier_rds.address
# }


# # --- OUTPUT COGNITO ---
# output "cognito_user_pool_id" {
#   description = "ID del Cognito User Pool"
#   value       = aws_cognito_user_pool.weather_scanner_user_pool.id
# }

# output "cognito_user_pool_client_id" {
#   description = "ID del Cognito User Pool Client"
#   value       = aws_cognito_user_pool_client.weather_scanner_app_client.id
# }

# output "cognito_user_pool_domain_url" {
#   description = "URL del dominio ospitato per l'interfaccia utente di Cognito"
#   value       = "https://${aws_cognito_user_pool_domain.weather_scanner_domain.domain}.auth.${aws_cognito_user_pool.weather_scanner_user_pool.region}.amazoncognito.com"
# }


#############################
#                           #
#      OUTPUT COGNITO       #
#                           #
#############################
output "cognito_user_pool_id" {
  value       = aws_cognito_user_pool.main.id
  description = "ID del User Pool Cognito"
}

output "cognito_app_client_id" {
  value       = aws_cognito_user_pool_client.main.id
  description = "ID del App Client Cognito"
}

output "cognito_app_client_secret" {
  value       = aws_cognito_user_pool_client.main.client_secret
  description = "Secret del App Client Cognito"
  sensitive   = true # Marca come sensibile per non stamparlo in console
}

output "cognito_domain" {
  value       = "${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
  description = "Dominio completo della Cognito Hosted UI"
}

output "cognito_redirect_uri" {
  value       = aws_cognito_user_pool_client.main.callback_urls[0] # Assumi che ce ne sia uno solo o prendi il primo
  description = "URL di redirect per Cognito"
}