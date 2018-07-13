#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'

echo -e "${BLUE}Do you want to set up an GCE Ingress Controller?"
tput sgr0

read -p "Y/N [N]: " deploy_gce_ingress
echo

if [[ $deploy_gce_ingress =~ ^([yY][eE][sS]|[yY])$ ]]; then
  
  # Input Domain
  echo
  echo -e "${GREEN}Type your domain name."
  tput sgr0

  read -p "domain: " domain_name

  sed -i -e 's/domain_name/'"$domain_name"'/g' ./gce-ingress.yaml

  # Input GCE Global Static IP name
  echo
  echo -e "${GREEN}Type the GCE Global Static IP name."
  tput sgr0

  read -p "IP name: " ip_name

  sed -i -e 's/gce_static_ip_name/'"$ip_name"'/g' ./gce-ingress.yaml

  # Input GCE SSL Cert name
  echo
  echo -e "${GREEN}Do you want to use an existing GCP SSL certificate?"
  tput sgr0

  read -p "Y/N [N]: " ssl
  if [[ $ssl =~ ^([yY][eE][sS]|[yY])$ ]]; then
    read -p "SSL Cert name: " cert_name
    sed -i -e 's/gce_cert_name/'"$cert_name"'/g' ./gce-ingress.yaml
    
    # Allow/disallow HTTP
    echo
    echo -e "${GREEN}Do you want to allow HTTP?"
    tput sgr0

    read -p "Y/N [N]: " allow_http
    if [[ $allow_http =~ ^([yY][eE][sS]|[yY])$ ]]; then
        sed -i -e 's/allow_http/'"true"'/g' ./gce-ingress.yaml
    else
        sed -i -e 's/allow_http/'"false"'/g' ./gce-ingress.yaml
    fi
  else
    sed '/ingress.gcp.kubernetes.io/pre-shared-cert: '"gce_cert_name"'/d' ./gce-ingress.yaml
    sed -i -e 's/allow_http/'"true"'/g' ./gce-ingress.yaml
  fi

  # Want to enable IAP?
  echo
  echo -e "${GREEN}Do you want to enable IAP (Identity Aware Proxy)?"
  tput sgr0

  read -p "Y/N [N]: " iap_enabled
  if [[ $iap_enabled =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sed -i -e 's/iap_enabled/'"true"'/g' ./gce-ingress.yaml
    read -p "OAuth Client ID: " client_id
    sed -i -e 's/oauth_client_id/'"$client_id"'/g' ./gce-ingress.yaml
    read -p "OAuth Client Secret: " client_secret
    sed -i -e 's/oauth_client_secret/'"$client_secret"'/g' ./gce-ingress.yaml
  else
    sed -i -e 's/iap_enabled/'"false"'/g' ./gce-ingress.yaml
  fi

  #GCE ingress
  echo
  echo -e "${BLUE}Deploying  K8S Ingress Controller"
  tput sgr0
  kubectl apply -f ./gce-ingress-backend-controller.yaml
  kubectl apply -f ./gce-ingress.yaml

  #wait for the ingress to become available.
  echo
  echo -e "${BLUE}Waiting 10 seconds for the Ingress Controller to become available."
  tput sgr0
  sleep 10

  #get ingress IP and hosts, display for user
  PROM_INGRESS=$(kubectl get ing --namespace=monitoring)
  echo
  echo 'Configure "/etc/hosts" or create DNS records for these hosts:' && printf "${RED}$PROM_INGRESS"
  echo
fi

#remove  "sed" generated files
rm ./*.yaml-e

echo
#cleanup
echo -e "${GREEN}Cleaning modified files"
tput sgr0

git checkout *

echo
echo -e "${GREEN}Done"
tput sgr0
