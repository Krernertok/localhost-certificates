# localhost-certificates

Creating a personal CA certificate allows localhost-testing to resemble production more accurately 
as you will be able to create trusted certificates for your own needs. However creating and storing
your own CA certificates can be a bit tedious, as you need to remember where you stored the CA you 
created last year and you may end up creating a new CA for all your localhost testing needs. While 
this works, it will most likely leave a bunch of unused and forgotten CA certificates to your browser 
and/or system CA store and this may cause security issues if someone gains access to your 
(unencrypted) CA certificates.

This docker aims to add more structure and security for self signed certificates. It uses 
[Hashicorp Vault](https://www.vaultproject.io/) to create and store the Root and CA certificate and 
the default setup also creates a localhost policy that limits the certficate creation for localhost 
-domain only (including subdomains).

Note that this will not create a super secure enviroment, but it should be better than just creating
CA certificates with openssl and in any case it offers a handy storage for them as well.

## Usage

### TL;DR

```
docker-compose up -d
docker-compose logs|grep 'unseal key'
docker-compose exec vault cat /vault/certs/ca.pem
docker-compose down
docker-compose up -d
```

Store printed unseal key to some secure place and import the printed certificates to your browser and/or system CA storage

go to [https://localhost:8200], unseal with unseal key and log in with admin / admin

### More detailed instructions

The docker-compose has three environment variables with default values

```
USERNAME (default: admin)
PASSWORD (default: admin)
DOCKER_SUBNET (default: 172.16.16.0/30)
```

To override these, you can create an .env -file and add your preferred change to that before starting the docker
initially. Changing at least the default password is recommendable. You may either uncomment the environment-file
section from the docker-compose -file or use `--env-file` switch when initially running the docker-compose

When you've made the changes you want, you're all set for the initial run:

```
## If you made .env -file
docker-compose --env-file .env up -d

## If you didn't make .env -file
docker-compose up -d
```

When the docker is up and running, check and save unseal key:

```
docker-compose logs|grep 'unseal key'
```

Check and save the Root and Intermediate CA serts

```
docker-compose exec vault cat /vault/certs/ca.pem
```

Import the certificates to your browser and/or systems CA store(s)

Clean or remove your password from the .env file.

shut down and start up the docker environment to clear logs (removes the unseal key).
Note that unless you changed the DOCKER_SUBNET in the .env -file, you don't need to 
add it to the startup anymore.

```
docker-compose down
docker-compose up -d
```

Direct your browser to [https://localhost:8200] and unseal the vault with the unseal key 
and log in with the credentials you set earlier or use the default credentials admin / admin.

Now you may use the pki_int/localhost -role to create certificates for localhost domain. Note that by default
the certificates will have TTL for 30 days, so if you want to have longer lasting certificates, click the `options` -link
before hitting `generate`

## What does it do actually?

The initial run will create three docker volumes

* vault_certs
* vault_file
* vault_logs

It will also set up vault for you:

* Creates one unseal key for you (three unseal keys wouldn't make sense with this sort of setup)
* Creates an admin policy with sufficient permissions for fiddling with vault.
* Enables pki secrets for Root certificate, this certificate has 10 years validity
* Creates an Intermediate certificate for signign user certificates, this certificate has 5 years validity
* Creates a certificate for localhost to be used with vault
* Enables user/password authentication and creates an admin user, uses either the default values or the ones you've set for overriding the defaults

Note that the admin policy allows quite wide permissions to interact with the vault, it does not limit the usage for certificates, but you may use it for
other purposes as well.

## Additional features
Additional features for vault.

### SSH certificates
The setup and instructions are based on hashicorps instructions:
https://developer.hashicorp.com/vault/docs/secrets/ssh/signed-ssh-certificates

To enable ssh-certificates when starting the environment first time, edit the docker-compose.yml file and add following
environment variable:

```
ENABLE_SSH_CERTS: True
```

If you already have a runnign vault you can just run the additional_features.sh -script, but first you'll need to edit your
policy and set it to allow access to ssh-*, add following to the admin policy:

```
# manage ssh
path "ssh-*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}
```

Then you can run the script

```
bash additional_features.sh
```

This will activate two more vaults:

* ssh-certs
* ssh-host-signer

#### Testing SSH certificates

You can use the sshtest container located in this repo for testing the SSH certs out:

First Get trusted CA for ssh connections:

```
vault read -field=public_key ssh-certs/config/ca > sshtest/trusted-user-ca-keys.pem
```

Then build and start the container

```
cd sshtest
docker build -t sshtest .
docker run --rm -p 127.0.0.1:2222:22 -it sshtest
```

Then get signed cert for ssh connection:

```
## First generate an ssh key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/testkey

## then get signed certificate for it:
vault write -field=signed_key ssh-certs/sign/ssh-role public_key=@$HOME/.ssh/testkey.pub > $HOME/.ssh/testkey-cert.pub
```

Now ssh connection should work with the certificate:

```
ssh -i ~/.ssh/testkey -p 2222 localhost -l ubuntu
```

#### Additional options

You can change the default behavior of the additional_features.sh with environment variables:

* SSH_CERTS_PATH
  * This can be used for changing the client certs vault name
  * NOTE: If you change this to be something else than ssh-* you need to alter the policy as well
* SSH_ALLOWED_USERS
  * You can set the allowed user names with this environment variable as comma separated list
  * In addition to these users, the vault user used for accessing the vault is always allowed
  * Default: ubuntu,root,ec2-user
* SSH_DEFAULT_USER
  * If you don't specify any valid_principals in the key signing request, this is the user that will be used
  * Default: `ubuntu`
* SSH_DEFAULT_TTL
  * Default TTL for the generated certificate
  * Default: 30m0s
* SSH_MAX_TTL
  * Maximum TTL for the certificate that can be set with ttl in the request
  * Default: 60m0s
* ALLOWED_EXTENSIONS
  * What extensions are allowed for the ssh key
  * Default: permit-pty,permit-port-forwarding
* SSH_HOST_CERTS_PATH
  * Key vault path for ssh host certificates
  * Default: ssh-host-signer
* SSH_HOST_ALLOWED_DOMAINS
  * Allowed domains for generating host certificates
  * Default: localhost,localdomain
* SSH_HOST_MAX_LEASE
  * Maximum TTL for host certificate
  * Default: 87600h
* SSH_HOST_DEFAULT_TTL
  * Default TTL for host certificates
  * Default: 87600h

To change the default values when requesting a signed cert for key, you can use switches when requesting the key

change allowed_principals (user for whom the cert is valid)

```
### Specify valid_principals as comma separated list
vault write -field=signed_key ssh-certs/sign/ssh-role valid_principals=ec2-user,root public_key=@$HOME/.ssh/testkey.pub > $HOME/.ssh/testkey-cert.pub
```

Change ttl for the key

```
vault write -field=signed_key ssh-certs/sign/ssh-role ttl=45m30s public_key=@$HOME/.ssh/testkey.pub > $HOME/.ssh/testkey-cert.pub
```
