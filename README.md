1. Installare Terraform 
2. Inizializzare infrastruttura
    2a. Creare le VPC
    2b. Creare le firewall rule
    2c. Creare RDS
------


Cosa stiamo facendo?

Abbiamo inizializzato il provider (providers.tf) di AWS, perché? Vogliamo tirare su l'infrastruttura di AWS e ci servono le risorse di AWS. Procediamo con l'autenticazione.

Come ci autentichiamo?

Usando il tool aws-cli e le credenziali di default. Copiamo il contenuto che ci da il lab e poi lo incolliamo dentro ~/.aws/credentials. Verifichiamo che ci autentichiamo correttamente:

aws sts get-caller-identity

--------------


Abbiamo il codice scritto. Inizializziamo la configurazione.

terraform init


Una volta inizializzato lo spazio (che va fatto solo una volta o nel caso in cui si aggiungano moduli -- NON RISORSE, ATTENTO!), possiamo passare alla fase di plan (vedo quali risorse ho dichiarato sul codice.)

terraform plan

Il plan mostrato ci torna? Le modifiche che terraform ci ha proposto sono concordi a quello che ci aspettiamo? Se si allora possiamo dare apply:

terraform apply

Abbiamo finito di lavorare?

terraform destroy# weather-scanner-iac
