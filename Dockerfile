FROM hashicorp/vault

ARG VAULT_ADDR=http://127.0.0.1:8200
RUN apk add --no-cache ca-certificates jq openssl
COPY configuration/server.hcl /vault/server.hcl 
COPY configuration/admin_policy.hcl /vault/admin_policy.hcl
COPY configuration/user_template.json /vault/user_template.json
COPY configuration/server-ssl.hcl /vault/config/server.hcl
COPY init.sh /vault/init.sh
COPY additional_features.sh /vault/additional_features.sh
WORKDIR /vault
RUN chmod +x /vault/init.sh
