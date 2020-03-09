#!/bin/bash -e
set -x
exec 1> >(tee /var/log/instance-setup.log) 2>&1
apt-get update 2>&1 >/dev/null
DEBIAN_FRONTEND=noninteractive apt-get upgrade -yq 2>&1 >/dev/null
apt-get -y -qq install    apt-transport-https    ca-certificates    curl    software-properties-common 2>&1 >/dev/null
curl -fsSL https://download.docker.com/linux/ubuntu/gpg |    apt-key add -
if [[ $(apt-key fingerprint 0EBFCD88) ]];
then
    add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
       $(lsb_release -cs) \
       stable"
    apt-get update 2>&1 >/dev/null
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -yq 2>&1 >/dev/null
    apt-get -y -qq install docker-ce  >/dev/null
    usermod -aG docker ubuntu
    curl -L https://raw.githubusercontent.com/docker/compose/1.24.1/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
fi

#reboot the system
systemctl reboot
