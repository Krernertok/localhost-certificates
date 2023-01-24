FROM ubuntu:22.04

RUN apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y ssh && \
  mkdir /run/sshd && \
  useradd -m -s /bin/bash ubuntu && \
  touch /var/log/ssh.log && \
  ln -sf /proc/1/fd/1 /var/log/ssh.log && \
  echo 'TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem' >> /etc/ssh/sshd_config && \
  echo 'HostKey /etc/ssh/ssh_host_rsa_key' >>  /etc/ssh/sshd_config && \
  echo 'HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub' >> /etc/ssh/sshd_config

COPY trusted-user-ca-keys.pem ssh_host_rsa_key ssh_host_rsa_key.pub ssh_host_rsa_key-cert.pub /etc/ssh/

ENTRYPOINT /usr/sbin/sshd -f /etc/ssh/sshd_config -E /var/log/ssh.log -D

