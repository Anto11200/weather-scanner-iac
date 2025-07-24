resource "aws_sns_topic" "main" {
  name              = "weather-daily-notifications"

  tags = {
    Name        = "weather-notifications-topic"
    Environment = "production"
    Project     = "WeatherScraper"
    ManagedBy   = "Terraform"
  }
}

# Sottoscrizione via email
# resource "aws_sns_topic_subscription" "main" {
#   for_each = toset([
#     "lauroantonio01@gmail.com"
#   ])
#   # Questa stringa dovrebbe comprendere la lista delle email sottoscritte.
#   # Non posso aggiornare sempre manualmente questa lista

#   topic_arn = aws_sns_topic.main.arn
#   protocol  = "email"

#   endpoint = each.value
# }