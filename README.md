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
