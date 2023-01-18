#!/bin/sh

    #default_extensions={"permit-pty": ""} \

function init_ssh_certs() {
  echo "Enabling support for SSH certificates"
  CERTS_PATH=${SSH_CERTS_PATH:-ssh-certs}
  ALLOWED_USERS=${SSH_ALLOWED_USERS:-ubuntu,ec2-user,root}
  DEFAULT_USER=${SSH_DEFAULT_USER:-ubuntu}
  DEFAULT_TTL=${SSH_DEFAULT_TTL:-30m0s}
  MAX_TTL=${SSH_DEFAULT_TTL:-60m0s}
  USERPASS_ACCESSOR=$(vault read sys/auth -format=json|jq -r '.data."userpass/".accessor')
  ALLOWED_DOMAINS=${SSH_ALLOWED_DOMAINS:-localhost,localdomain}
  HOST_MAX_LEASE=${SSH_HOST_MAX_LEASE:-87600h}
  HOST_DEFAULT_TTL=${SSH_HOST_DEFAULT_TTL:-87600h}
  vault secrets enable -path=${CERTS_PATH} ssh
  vault write ${CERTS_PATH}/config/ca generate_signing_key=true
  
  echo '{
    "algorithm_signer": "rsa-sha2-256",
    "allow_user_certificates": true,
    "allowed_users": "{{identity.entity.aliases.'"${USERPASS_ACCESSOR}"'.name}},'"${ALLOWED_USERS}"'",
    "allowed_extensions": "permit-pty,permit-port-forwarding",
    "default_extensions": {"permit-pty": ""},
    "key_type": "ca",
    "default_user": "'"${DEFAULT_USER}"'",
    "ttl": "'"${DEFAULT_TTL}"'",
    "max_ttl": "'"${MAX_TTL}"'"
  }' | vault write ${CERTS_PATH}/roles/ssh-role -
  vault secrets enable -path=ssh-host-signer ssh
  vault write ssh-host-signer/config/ca generate_signing_key=true
  vault secrets tune -max-lease-ttl=${HOST_MAX_LEASE} ssh-host-signer
  vault write ssh-host-signer/roles/hostrole \
    key_type=ca \
    algorithm_signer=rsa-sha2-256 \
    ttl=${HOST_DEFAULT_TTL} \
    allow_host_certificates=true \
    allowed_domains="${ALLOWED_DOMAINS}" \
    allow_subdomains=true
}
