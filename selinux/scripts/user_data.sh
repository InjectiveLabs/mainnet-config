#!/bin/bash

# FOR RHEL 8 / CentOS 8

# Some global variables
CONFIG_MONIKER=selinux-test3
CONFIG_PERSISTENT_PEERS=9bca3e793fbc8aaf39b55888c0db875944d6ee11@3.14.183.40:26656,5f85fceaa8a1fe1fc0067ab9e5687d9c2105c03b@3.15.11.190:26656,fbcb0739d630d92d15edf3c864da028fcf468982@63.33.59.187:26656
VALIDATOR_HOME=/home/injective.validator
INJECTIVED_LOG_OUT=/var/log/injectived.log
PEGGO_LOG_OUT=/var/log/peggo.log
NETWORK_GENESIS=https://raw.githubusercontent.com/InjectiveLabs/network-config/31660074274027b239281863fd1068a42e520372/staking/40009/genesis.json
PEGGO_ENV=
CHAIN_BIN_RELEASE_TAG=v4.0.9-1624286601

set -e

yum update -y
yum install -y unzip wget tree nano \
	selinux-policy selinux-policy-targeted setools-console

sestatus

echo "Setting SELinux policy to enforcing"
setenforce 1

echo "Disallow user/staff to exec content from home and /tmp"
semanage boolean -m --off user_exec_content
semanage boolean -m --off staff_exec_content

echo "Check SELinux policy:"
getenforce

echo "Adding injective.validator user of type user_u"
useradd -Z user_u injective.validator

echo "Adding injective.dev user of type staff_u"
useradd -Z staff_u injective.dev

echo "Adding staff group"
groupadd staff
usermod -a -G staff injective.dev

# wget -O /etc/sudoers.d/staff.sudo

echo "Copy ~/.ssh/authorized_keys to injective.dev"

mkdir /home/injective.dev/.ssh
cp ~/.ssh/authorized_keys /home/injective.dev/.ssh/
chown -R injective.dev /home/injective.dev/.ssh

echo "Copy ~/.ssh/authorized_keys to injective.validator"

mkdir /home/injective.validator/.ssh
cp ~/.ssh/authorized_keys /home/injective.validator/.ssh/
chown -R injective.validator /home/injective.validator/.ssh

echo "Setup update validator files tool"

wget https://github.com/InjectiveLabs/mainnet-config/releases/download/tool-release-2/update-validator-files_linux_amd64.zip \
	-O tmp.zip && unzip tmp.zip && rm tmp.zip

mv update-validator-files_linux_amd64/update-validator-files /usr/local/bin/
rmdir update-validator-files_linux_amd64

echo "Installing Geth binary for key management"
wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.10.4-aa637fd3.tar.gz \
	-O geth.tar.gz && tar xf geth.tar.gz && rm geth.tar.gz
mv geth-linux-amd64-1.10.4-aa637fd3/geth /usr/local/bin/
rm -rf geth-linux-amd64-1.10.4-aa637fd3
chcon "system_u:object_r:bin_t:s0" /usr/local/bin/geth

echo "Download SELinux policies for injectived, peggo and updater"
# wget -O /root/injectived-validator.pp
# wget -O /root/peggo-orchestrator.pp
# wget -O /root/injective-update.pp

echo "Installing injectived-validator.pp"
semodule -i /root/injectived-validator.pp
echo "Installing peggo-orchestrator.pp"
semodule -i /root/peggo-orchestrator.pp
echo "Installing injective-update.pp"
semodule -i /root/injective-update.pp

# After policies are loaded and installed, we can set appropriate SELinux contexts to everything

echo "Setting context for update-validator-files"
chcon "system_u:object_r:injective_update_exec_t:s0" /usr/local/bin/update-validator-files

echo "Creating injective.validator HOME layout with bin / config / data / peggo"

mkdir $VALIDATOR_HOME/bin
mkdir $VALIDATOR_HOME/config
mkdir $VALIDATOR_HOME/data
mkdir $VALIDATOR_HOME/peggo

touch $VALIDATOR_HOME/bin/injectived
chmod +x $VALIDATOR_HOME/bin/injectived
touch $VALIDATOR_HOME/bin/peggo
chmod +x $VALIDATOR_HOME/bin/peggo
touch $VALIDATOR_HOME/config/genesis.json
touch $VALIDATOR_HOME/peggo/.env

chcon "user_u:object_r:user_home_t:s0" $VALIDATOR_HOME/bin
chcon "user_u:object_r:user_home_t:s0" $VALIDATOR_HOME/config
chcon "user_u:object_r:user_home_t:s0" $VALIDATOR_HOME/data
chcon "user_u:object_r:user_home_t:s0" $VALIDATOR_HOME/peggo

chcon "user_u:object_r:injectived_exec_t:s0" $VALIDATOR_HOME/bin/injectived
chcon "user_u:object_r:peggo_exec_t:s0" $VALIDATOR_HOME/bin/peggo
chcon "user_u:object_r:user_home_t:s0" $VALIDATOR_HOME/config/genesis.json
chcon "user_u:object_r:user_home_t:s0" $VALIDATOR_HOME/peggo/.env

echo "Updating injectived and peggo executables"
update-validator-files \
	-chain-release-tag $CHAIN_BIN_RELEASE_TAG \
	-home-dir $VALIDATOR_HOME \
	-release-os linux-amd64

echo "Downloading injectived config template"
# wget -O $VALIDATOR_HOME/config/config.toml
# wget -O $VALIDATOR_HOME/config/app.toml
curl $NETWORK_GENESIS > $VALIDATOR_HOME/config/genesis.json

echo "Downloading peggo config template"
curl $PEGGO_ENV > $VALIDATOR_HOME/peggo/.env

chcon "user_u:object_r:user_home_t:s0" $VALIDATOR_HOME/config/config.toml
chcon "user_u:object_r:user_home_t:s0" $VALIDATOR_HOME/config/app.toml

echo "Node config template replacing vars"

sed -i 's|moniker = ""|moniker = "'$CONFIG_MONIKER'"|g' $VALIDATOR_HOME/config/config.toml
sed -i 's|persistent_peers = ""|persistent_peers = "'${CONFIG_PERSISTENT_PEERS}'"|g' $VALIDATOR_HOME/config/config.toml

echo "Installing Systemd Unit files"

# wget -O /etc/systemd/system/injective.service
# wget -O /etc/systemd/system/peggo.service

systemctl daemon-reload
systemctl enable injective

echo "[NOTE] Injectived enabled, not started"
echo "[NOTE] Peggo not enabled, not started"

echo "Prepare Systemd Unit logging output"

touch $INJECTIVED_LOG_OUT
chown -R injective.validator:injective.validator $INJECTIVED_LOG_OUT
chcon system_u:object_r:injectived_log_t:s0 $INJECTIVED_LOG_OUT
ls -Z $INJECTIVED_LOG_OUT

touch $PEGGO_LOG_OUT
chown -R injective.validator:injective.validator $PEGGO_LOG_OUT
chcon system_u:object_r:peggo_log_t:s0 $PEGGO_LOG_OUT
ls -Z $PEGGO_LOG_OUT

echo "Moving SSH port to 2200"
semanage port -a -t ssh_port_t -p tcp 2200
sed -i 's|#Port 22|Port 2200|g' /etc/ssh/sshd_config

echo "Disabling root login over SSH"
sed -i 's|PermitRootLogin yes|PermitRootLogin no|g' /etc/ssh/sshd_config
systemctl restart sshd

echo "Disabling root login shell"
sed -i 's|root:x:0:0:root:/root:/bin/bash|root:x:0:0:root:/root:/sbin/nologin|g' /etc/passwd

echo "Disable the serial console (TTYS1) login"
mv /etc/securetty /etc/securetty.orig
touch /etc/securetty
chmod 600 /etc/securetty

echo "Init validator files"

wget https://github.com/InjectiveLabs/mainnet-config/releases/download/tool-release-1/init-validator-files_linux_amd64.zip \
	-O tmp.zip && unzip tmp.zip && rm tmp.zip

mv init-validator-files_linux_amd64/init-validator-files /usr/local/bin/
rmdir init-validator-files_linux_amd64

init-validator-files -root-dir /validator

semanage fcontext -a -t validator_config_t -- "/validator(/.*)?"
restorecon -Rv /validator
chown -R injective.validator:injective.validator /validator

echo "Remap unconfined root to sysadm"
semanage login -m -S targeted -s "sysadm_u" -r s0-s0:c0.c1023 root

echo "Prevent any future SELinux policy changes"
semanage boolean --on secure_mode_policyload

