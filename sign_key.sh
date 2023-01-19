#!/bin/bash

error=0
red='\033[0;31m'
yellow='\033[0;33m'
nc='\033[0m'

function help() {
  echo "Usage: $0 <public-key> [-u <username>] [-t <ttl>] [-e <extensions>]"
  echo ""
  echo -e "-u|--users\tUsers (principals) for key, can have several keys as comma separated list"
  echo -e "-t|--ttl\tTTL for the certificate"
  echo -e "-e|--extensions\tList of extensions to add for the key"
}

command -v vault >/dev/null 2>&1 || { echo -e >&2 "${red}ERROR: ${yellow}vault${nc} is required, but not installed";error=1; }
command -v jq >/dev/null 2>&1 || { echo -e >&2 "${red}ERROR: ${yellow}jq${nc} is required, but not installed";error=1; }

if [ $error -eq 1 ]; then
  exit 1
fi

if [ $# -eq 0 ]; then
    help
    exit 1
fi

while [[ $# -gt 0 ]]
    do
        opt="$1"
        case $opt in
            -u|--user)
                user="$2"
                shift
                shift
            ;;
            -t|-ttl)
                ttl="$2"
                shift
                shift
            ;;
            -e|--extensions)
                extensions="$2"
                shift
                shift
            ;;
            *)
                if [ -f $1 ]; then
                    public_key=$1
                else
                    echo "Unknown parameter $1"
                fi
                shift
            ;;
    esac
done

if [ "${public_key}x" == "x" ]; then
  echo -e "${red}ERROR: No public key provided${nc}"
  echo ""
  help
  exit 1
fi

key_data=$(cat ${public_key})

if [[ ${key_data} != ssh-* ]]; then
  echo "${public_key} does not seem like ssh public key, unable to continue"
  exit 1
fi

if [ "${VAULT_ADDR}x" == "x" ]; then
  read -p "Enter vault address: " VAULT_ADDR
fi

if [ "${VAULT_TOKEN}x" == "x" ]; then
  read -s -p "Enter vault token: " VAULT_TOKEN
fi
payload_start='{'
payload_end='}'
payload="\"public_key\":\"${key_data}\""
if [ "${user}x" != "x" ]; then
  payload="${payload},\"valid_principals\":\"${user}\""
fi

if [ "${ttl}x" != "x" ]; then
  payload="${payload},\"ttl\":\"${ttl}\""
fi
cert_name="${public_key%.*}-cert.pub"
echo "writing cert to ${cert_name}"
echo "${payload_start}${payload}${payload_end}"|vault write -field=signed_key ssh-certs/sign/ssh-role - > ${cert_name}
