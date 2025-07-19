# Questo è il tuo directory utente dove gli utenti si registrano e autenticano.
resource "aws_cognito_user_pool" "weather_scanner_user_pool" {
  name = "weather-scanner-users"

  auto_verified_attributes = ["email"]

  # Impostazione per il recupero della password tramite email
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # 
  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  # Attributi standard che vuoi richiedere o rendere obbligatori
  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = true
    required            = true
  }

  # Amazon Cognito User Pool Client (App Client)
  # L'applicazione userà questo client per interagire con l'User Pool.
  resource "aws_cognito_user_pool_client" "weather_scanner_app_client" {
    name                          = "weather-scanner-client"
    user_pool_id                  = aws_cognito_user_pool.weather_scanner_user_pool.id

    generate_secret               = false # Impostiamo a true solo per backend che usano un client segreto
    
    allowed_oauth_flows       = ["code"]
    allowed_oauth_scopes      = ["email", "openid", "profile"]
    allowed_oauth_flows_user_pool_client = true

    # URL di redirect per i flussi di autenticazione basati su browser
    callback_urls = ["http://localhost:3000/callback", "https://your-app.com/callback"]
    logout_urls   = ["http://localhost:3000/logout", "https://your-app.com/logout"]

    supported_identity_providers = ["Google"]
  }

  resource "aws_cognito_identity_provider" "google" {
    user_pool_id = aws_cognito_user_pool.weather_scanner_user_pool.id
    provider_name = "Google"
    provider_type = "Google"

    provider_details = {
      client_id     = "GOOGLE_CLIENT_ID"
      client_secret = "GOOGLE_CLIENT_SECRET"
      authorize_scopes = "profile email openid"
    }

    # Attributi di google che verranno mappati nei campi cognito
    attribute_mapping = {
      email       = "email"
      given_name  = "given_name" # vedere se devono essere modificati
      family_name = "family_name" # vedere se devono essere modificati
    }
  }

  resource "aws_cognito_identity_pool" "weather_scanner_users_pool" {
    identity_pool_name               = "federated-identity-pool"
    allow_unauthenticated_identities = false

    cognito_identity_providers {
      client_id         = aws_cognito_user_pool_client.weather_scanner_app_client.id
      provider_name     = aws_cognito_user_pool.weather_scanner_user_pool.endpoint
      server_side_token_check = false
    }
  }

  # Configurazione dell'MFA (Multi-Factor Authentication)
  mfa_configuration = "OFF"

  # Nomi dei campi che permettono agli utenti di accedere (username, email, phone_number)
  username_attributes = ["email"] # Gli utenti potranno usare l'email come username

  tags = {
    Name        = "weather-scanner-user-pool"
    Environment = "FreeTier"
  }
}



# Amazon Cognito User Pool Domain
# Permette di ospitare una pagina di login/registrazione/recupero password
# fornita da Cognito con un tuo dominio personalizzato o un sottodominio di amazoncognito.com.
resource "aws_cognito_user_pool_domain" "weather_scanner_domain" {
  domain       = "weather-scanner-app-domain-${random_string.suffix.result}" # Dominio univoco. Sostituisci o usa una variabile.
  user_pool_id = aws_cognito_user_pool.weather_scanner_user_pool.id
}

# Stringa casuale per garantire l'univocità del dominio Cognito (devono essere globalmente unici)
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
}