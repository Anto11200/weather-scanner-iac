#!/bin/bash
set -euo pipefail

# Parametri DB remoti
DB_HOST="rds-instance.cpkfci27pmjq.us-east-1.rds.amazonaws.com"
DB_PORT="3306"
DB_USER="admin"
DB_PASSWORD="mypassword"
DB_NAME="weatherdb"

echo "🛠️ Verifica o creazione database remoto $DB_NAME su $DB_HOST..."
docker run --rm mysql:8.0 \
  mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" \
  -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

echo "✅ Database $DB_NAME esistente o creato."

# Setup GKE credentials
echo "🔐 Acquisizione credenziali GKE..."
gcloud container clusters get-credentials weather-scanner-gke --region europe-west12 --project weatherscanner-466411

echo "🔧 Impostazione tls-server-name..."
kubectl config set-cluster gke_weatherscanner-466411_europe-west12_weather-scanner-gke --server=https://127.0.0.1:8443 --tls-server-name=$(gcloud container clusters describe weather-scanner-gke --region europe-west12 --format="value(privateClusterConfig.privateEndpoint)")

# Tunnel SSH: evita duplicazione se già attivo
echo "🛜 Verifica tunnel SSH..."
if ! lsof -i :8443 >/dev/null; then
  gcloud compute ssh --zone "europe-west12-b" "gke-bastion-host" --tunnel-through-iap --project "weatherscanner-466411" -- -fNL 8443:$(gcloud container clusters describe weather-scanner-gke --region europe-west12 --format="value(privateClusterConfig.privateEndpoint)"):443
  echo "🔗 Tunnel SSH avviato."
else
  echo "🔁 Tunnel SSH già attivo sulla porta 8443."
fi

# Migrazioni Django: idempotenti per natura
echo "🧩 Applicazione migrazioni Django..."
kubectl exec deploy/django -- python manage.py migrate --noinput

# Applica manifest solo se ci sono modifiche (usa `kubectl diff`)
echo "📄 Applico manifest se ci sono modifiche..."
kubectl diff -f ./cluster-manifests >/dev/null 2>&1 || {
  kubectl apply -f ./cluster-manifests
  echo "✅ Manifest applicati."
}

# Import MongoDB solo se la collezione è vuota
MONGO_URI="mongodb://foo:mustbeeightchars@weather-scanner-nlb-ad65dd6f7883376f.elb.eu-west-1.amazonaws.com:27017/weather_scanner?tls=true&retryWrites=false&tlsInsecure=true&directConnection=true"
CONFIG_DIR="./configs"

echo "📦 Avvio import MongoDB da $CONFIG_DIR..."
for file in "$CONFIG_DIR"/*.json; do
    filename=$(basename "$file")
    collection="${filename#weather_scanner.}"
    collection="${collection%.json}"

    echo "🔍 Verifico se la collezione '$collection' è vuota..."

    count=$(docker run --rm -v "$PWD:/app" python:3.11-slim bash -c "
        pip install --quiet pymongo && \
        python3 -c '
import os
from pymongo import MongoClient
uri = \"$MONGO_URI\"
collection = \"$collection\"
client = MongoClient(uri)
count = client.get_default_database()[collection].count_documents({})
print(count)
'" \
    )

    if [[ "$count" == "0" ]]; then
        echo "📂 Importazione $filename in '$collection'..."
        docker run --rm -v "$PWD:/data" mongo:7.0 \
          mongoimport --uri="$MONGO_URI" \
                      --collection="$collection" \
                      --file="/data/$file" \
                      --jsonArray
    else
        echo "⏭️ Collezione '$collection' già popolata ($count documenti), salto."
    fi
done


kubectl create secret generic "aws-credentials" \
  --from-file="credentials=/home/antonio/.aws/credentials" \
  --dry-run=client -o yaml | kubectl apply -f -

  
kubectl create secret generic db-secret --from-literal=password=mypassword

echo "✅ Tutte le operazioni completate in modo idempotente."

