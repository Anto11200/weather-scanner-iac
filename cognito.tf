# Questo è il tuo directory utente dove gli utenti si registrano e autenticano.
resource "aws_cognito_user_pool" "weather_scanner_user_pool" {
  name = "weather-scanner-users"

  # Policy per la complessità della password
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
    temporary_password_validity_days = 7 # Opzionale: validità password temporanea
  }

  # Configurazione per l'invio delle email (per verifica, reset password)
  # Usiamo il servizio di email predefinito di Cognito.
  # Se superiamo il limite del free tier di email di Cognito (1000/mese),
  # dovremmo configurare Amazon SES per invii più consistenti.
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT" # Usa il servizio predefinito di Cognito
    # source_arn          = "arn:aws:ses:REGION:ACCOUNT_ID:identity/YOUR_VERIFIED_EMAIL_OR_DOMAIN" # Se si vuole usare SES
  }

  # Attributi standard che vuoi richiedere o rendere obbligatori
  schema {
    name = "email"
    attribute_data_type = "String"
    mutable  = true
    required = true
  }
  # Puoi aggiungere altri attributi come 'name', 'phone_number', etc.

  # Configurazione dell'MFA (Multi-Factor Authentication)
  # Per un free tier, potresti voler disabilitare l'MFA per ridurre la complessità
  # o attivare solo l'MFA facoltativo per gli utenti.
  mfa_configuration = "OFF" # Off, ON (richiesto), OPTIONAL (facoltativo)

  # Nomi dei campi che permettono agli utenti di accedere (username, email, phone_number)
  username_attributes = ["email"] # Gli utenti potranno usare l'email come username

  # Policy per i nomi utente, se vuoi renderli case-insensitive
  username_configuration {
    case_sensitive = false
  }

  # Configurazione della disattivazione/cancellazione utente
  # account_recovery_setting {
  #   recovery_mechanism {
  #     name     = "verified_email"
  #     priority = 1
  #   }
  # }

  tags = {
    Name = "weather-scanner-user-pool"
    Environment = "FreeTier"
  }
}

# Amazon Cognito User Pool Client (App Client)
# Le tue applicazioni (web, mobile) useranno questo client per interagire con il User Pool.
resource "aws_cognito_user_pool_client" "weather_scanner_app_client" {
  name = "weather-scanner-client"
  user_pool_id = aws_cognito_user_pool.weather_scanner_user_pool.id
  generate_secret = false # Impostiamo a true solo per backend che usano un client segreto
  explicit_auth_flows = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_PASSWORD_AUTH"] # Flussi di autenticazione abilitati
  prevent_user_existence_errors = "ENABLED" # Impedisce di rivelare se un utente esiste o meno in fase di login/registrazione

  # URL di redirect per i flussi di autenticazione basati su browser (es. interfaccia UI ospitata)
  # Devi specificare gli URL a cui Cognito può reindirizzare l'utente dopo l'autenticazione/logout.
  # Sostituisci con gli URL reali della tua applicazione.
  callback_urls = ["http://localhost:3000/callback", "https://your-app.com/callback"]
  logout_urls   = ["http://localhost:3000/logout", "https://your-app.com/logout"]

  # Abilita i tipi di concessione OAuth (Code Grant, Implicit Grant)
  allowed_oauth_flows = ["code"]
  allowed_oauth_flows_user_pool_client = true # Questo è cruciale per i client che non hanno un segreto
  allowed_oauth_scopes = ["phone", "email", "openid", "profile", "aws.cognito.signin.user.admin"]

  # Tempo di scadenza dei token (in minuti, 1440 minuti = 24 ore)
  access_token_validity     = 60
  id_token_validity         = 60
  refresh_token_validity    = 20160 # 28 giorni
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