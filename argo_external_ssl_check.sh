#!/bin/bash

# This Bash script processes a file containing multiple certificates in the format "-----BEGIN CERTIFICATE-----" and "-----END CERTIFICATE-----".
# Checks expiration dates for each certificate and logs the results.

# Check if a file path is provided as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

input_file="$1"
certificate_started=false
current_cert=""
valid_count=0
expiring_soon_count=0
invalid_count=0

while IFS= read -r line || [[ -n "$line" ]]; do
    line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [[ "$line" == "-----BEGIN CERTIFICATE-----" ]]; then
        certificate_started=true
        current_cert=""
    fi

    if [ "$certificate_started" == "true" ]; then
        current_cert+="$line"$'\n'
        if [[ "$line" == "-----END CERTIFICATE-----" ]]; then
            certificate_started=false
            subject=$(openssl x509 -noout -subject 2>/dev/null <<< "$current_cert")
            issuer=$(openssl x509 -noout -issuer 2>/dev/null <<< "$current_cert")
            expiry=$(echo "$current_cert" | openssl x509 -noout -enddate 2>/dev/null | sed 's/notAfter=//')
            # Check the validity of the certificate
            validity_check=$(echo "$current_cert" | openssl x509 -noout -checkend 0 2>/dev/null)
            if [ $? -eq 0 ]; then
              # Check the validity of the certificate for the next week
              next_week_validity_check=$(echo "$current_cert" | openssl x509 -noout -checkend 604800 2>/dev/null)
              if [ $? -eq 0 ]; then
                valid_count=$((valid_count+1))
                echo -e "Valid Certificate: \n $subject \n $issuer \n Expiry Date: $expiry \n"
              else
                expiring_soon_count=$((expiring_soon_count+1))
                echo -e "Expiring Soon: \n $subject \n $issuer \n Expiry Date: $expiry \n$current_cert \n"
              fi
            else
                invalid_count=$((invalid_count+1))
                echo -e "Invalid Certificate: \n $subject \n $issuer \n Expiry Date: $expiry \n"
            fi
        fi
    fi
done < "$input_file"
echo -e "$valid_count valid certificates, \n$expiring_soon_count certificates expiring soon, \n$invalid_count invalid certificates found."

env_url="<https://argo-workflows.ci-prod.internal.token.io/cron-workflows/argocd/cert-check-prod|Logs>"
if [[ "$TARGET_ENV" == "SANDBOX" ]]; then
  env_url="<https://argo-workflows.ci-prod.internal.token.io/cron-workflows/argocd/cert-check-sandbox|Logs>"
fi
runbook_url="<https://tokenio.atlassian.net/wiki/spaces/EN/pages/3343286273/HOW-TO+update+expiring+soon+certificates|Runbook>"

if [[ -n "$SLACK_URL" && $expiring_soon_count -gt 0 ]]; then
  curl -X POST "$SLACK_URL" \
      -H "Content-Type: application/json" \
      --data "{
        \"text\": \"@team_platform There are $expiring_soon_count certificates expiring soon on $TARGET_ENV\n
        $env_url | $runbook_url\",
        \"link_names\": 1
      }"
fi
