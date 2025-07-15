# Un "topic" è un canale a cui i publishers inviano messaggi e i subscribers ricevono.
# Questa risorsa di per sé non ha un costo diretto se non utilizzata.
resource "aws_sns_topic" "application_alerts" {
  name = "weather-scanner-application-alerts" # Nome descrittivo per il tuo topic
}

# Sottoscrizione via email
resource "aws_sns_topic_subscription" "email_alerts_subscription" {
  topic_arn = aws_sns_topic.application_alerts.arn
  protocol  = "email"
  endpoint  = "tuo.email@example.com" # <--- SOSTITUISCI CON IL TUO INDIRIZZO EMAIL REALE
  # Ricorda di confermare la sottoscrizione via email.
}

resource "aws_sns_topic_subscription" "sqs_alerts_subscription" {
  topic_arn = aws_sns_topic.application_alerts.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.sns_alert_queue.arn
  # Le sottoscrizioni a SQS non richiedono conferma manuale
}