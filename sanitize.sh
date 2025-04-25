#!/bin/bash

RED=`tput setaf 1`
RESET=`tput sgr0`

echo "Removing /etc/sysconfig/rhn..."
rm -rf /etc/sysconfig/rhn
if [ $? -ne 0 ]; then
	echo "${RED}Could not remove /etc/sysconfig/rhn${RESET}"
fi

echo "Removing /boot/.rackspace..."
rm -rf /boot/.rackspace
if [ $? -ne 0 ]; then
	echo "${RED}Could not remove /boot/.rackspace${RESET}"
fi

echo "Removing /root/.rackspace..."
rm -rf /root/.rackspace
if [ $? -ne 0 ]; then
	echo "${RED}Could not remove /root/.rackspace${RESET}"
fi

echo "Removing the rack user..."
userdel -fr rack
if [ $? -ne 0 ]; then
	echo "${RED}Could not remove the rack user, will attempt to delete the home directory contents${RESET}"
	rm -rf /home/rack
	if [ $? -ne 0 ]; then
		echo "${RED}Could not delete all files from the rack users home directory${RESET}"
	fi
fi

echo "Removing Rackspace RPM packages..."
PKGS=`rpm -qa | awk '/^rs-/{printf "%s ", $1}'`
if [ -n "$PKGS" ]; then
	yum remove -q -y $PKGS
	if [ $? -ne 0 ]; then
		echo "${RED}Could not remove Rackspace RPM packages:${RESET}"
		echo $PKGS | sed 's/\ /\n/g'
	fi
fi

echo "Removing RHN RPM packages..."
PKGS=`rpm -qa | awk '/^rhn/{printf "%s ", $1}'`
if [ -n "$PKGS" ]; then
	yum remove -q -y $PKGS
	if [ $? -ne 0 ]; then
		echo "${RED}Could not remove RHN RPM packages:${RESET}"
		echo $PKGS | sed 's/\ /\n/g'
	fi
fi

echo "Removing Nimbus..."
/sbin/service nimbus stop > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "${RED}Could not stop nimbus, not attempting removal${RESET}"
else
	sleep 10
	/sbin/chkconfig --del nimbus
	if [ $? -ne 0 ]; then
		echo "${RED}Could not chkconfig nimbus off${RESET}"
	fi
	rm -rf /etc/init.d/nimbus /opt/nim{bus,soft}
	if [ $? -ne 0 ]; then
		echo "${RED}Could not remove /etc/init.d/nimbus /opt/nim{bus,soft}${RESET}"
	fi
fi

echo "Removing Sophos..."
if [ -e /opt/sophos-av/uninstall.sh ]; then
	/opt/sophos-av/uninstall.sh
fi
if [ -n "`rpm -q sophosav-installer`" ]; then
	yum remove -q -y sophosav-installer
	if [ $? -ne 0 ]; then
		echo "${RED}Could not remove the sophosav-installer RPM${RESET}"
	fi
fi

echo "Removing CommVault..."
if [ -e /etc/init.d/Galaxy ]; then
	/sbin/service Galaxy stop > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "${RED}Could not stop simpana, not attempting further removal${RESET}"
	else
		/sbin/chkconfig --del Galaxy
		CVPKGS=(
			/etc/init.d/Galaxy
			/etc/Galaxy.pkg
			/etc/CommVaultRegistry
			/var/log/galaxy
			/var/log/simpana
			/opt/galaxy
			/opt/Galaxy
			/opt/simpana
			/opt/Simpana
			/opt/CVPackages
			/usr/bin/simpana*
			/usr/sbin/simpana*
		)
		rm -rf ${CVPKGS[*]}
		if [ $? -ne 0 ]; then
			echo "${RED}Could not delete one of the following files or directories:${RESET}"
			echo "${CVPKGS[*]}" | tr -s ' ' '\n'
		fi
	fi
fi

echo "Removing MaaS Configuration..."
if [ -e /etc/init.d/rackspace-monitoring-agent ]; then
	/sbin/service rackspace-monitoring-agent stop > /dev/null 2>&1
	rm -f /etc/rackspace-monitoring-agent.cfg
	/sbin/chkconfig rackspace-monitoring-agent off
fi
