# Creazione User Pool Cognito 
resource "aws_cognito_user_pool" "weather_scanner" {
  name                      = "weather-scanner-users"

  # Verifica tramite email
  auto_verified_attributes  = ["email"]
  mfa_configuration         = "OFF" # Multi-factor Authentication

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = true
    required            = true
  }

  tags = {
    Name        = "weather-scanner-user-pool"
    Environment = "FreeTier"
  }
}

# Configurazione di Google come proider esterno
resource "aws_cognito_identity_provider" "google" {
  user_pool_id  = aws_cognito_user_pool.weather_scanner.id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    authorize_scopes = "openid email profile"
    client_id       = var.google_client_id
    client_secret   = var.google_client_secret
    attributes_url                = "https://people.googleapis.com/v1/people/me?personFields="
    attributes_url_add_attributes = "true"
    authorize_url                 = "https://accounts.google.com/o/oauth2/v2/auth"
    oidc_issuer                   = "https://accounts.google.com"
    token_request_method          = "POST"
    token_url                     = "https://www.googleapis.com/oauth2/v4/token"
  }

  attribute_mapping = {
    email    = "email"
    username = "sub"
  }
}

# Creazione del Dominio Cognito gestito
resource "aws_cognito_user_pool_domain" "weather_scanner_domain" {
  domain       = "weather-scanner-app"
  user_pool_id = aws_cognito_user_pool.weather_scanner.id

  # Dipendenza esplicita per assicurare che l'User Pool esista prima del dominio
  depends_on = [aws_cognito_user_pool.weather_scanner]
}

# Creazione client per l'applicazione
resource "aws_cognito_user_pool_client" "weather_scanner_app_client" {
  name                                 = "weather-scanner-client"
  user_pool_id                         = aws_cognito_user_pool.weather_scanner.id
  supported_identity_providers         = ["COGNITO", "Google"] # Attivazione provider esterno di Google
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  generate_secret                      = false

  # Da cambiare con le pagine in cui deve essere reindirizzato dopo il login e logout
  callback_urls                        = ["http://localhost:8000/cognito/google/callback/"] # Da cambiare in futuro con il DNS del cluster
  logout_urls                          = ["http://localhost:8000/login/"] # Da cambiare in futuro con il DNS del cluster

  # dipendenza esplicita per assicurare l'ordine corretto
  depends_on = [aws_cognito_identity_provider.google]
}