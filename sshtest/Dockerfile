FROM ubuntu:22.04

RUN apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y ssh && \
  mkdir /run/sshd && \
  useradd -m ubuntu && \
  echo 'TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem' >> /etc/ssh/sshd_config

COPY trusted-user-ca-keys.pem /etc/ssh/trusted-user-ca-keys.pem

ENTRYPOINT ['/usr/sbin/sshd','-f','/etc/ssh/sshd_config','-E','/var/log/ssh.log','-D']

