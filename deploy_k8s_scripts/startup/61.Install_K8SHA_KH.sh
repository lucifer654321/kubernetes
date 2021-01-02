#!/bin/bash
# 2020年12月6日
# Auto Deployment The K8S HA with Keepalived & HAProxy
# BY：Lucifer
########################################################

if [ ${SCRIPTS_DIR} == "" ];then
        SCRIPTS_DIR=$(cd ..; pwd)
fi
source ${SCRIPTS_DIR}/env/directory_set.sh
HA_WORK_CONF_DIR="${WORK_DIR}/conf/ha"

#######################################
# set variables below to create the config files, all files will create at ./config directory
#######################################


if [ $? == 0 ];then
	for i in `seq ${#MASTER_IPS[@]}`
	do
        	K8SHA_IPS[i-1]="${MASTER_IPS[i-1]}"
        	K8SHA_HOSTS[i-1]="${MASTER_NAMES[i-1]}"
	done
		export K8SHA_VIP="${VIP}"
		export K8SHA_NETINF="${IFACE}"
		export K8SHA_KEEPALIVED_AUTH=412f7dc3bfed32194d1600c483e10ad1d
else
	# master keepalived virtual ip address
	export K8SHA_VIP=192.168.49.200

	# master01 ip address
	export K8SHA_IP1=192.168.49.101

	# master02 ip address
	export K8SHA_IP2=192.168.49.102

	# master03 ip address
	export K8SHA_IP3=192.168.49.103

	# master01 hostname
	export K8SHA_HOST1=master01

	# master02 hostname
	export K8SHA_HOST2=master02

	# master03 hostname
	export K8SHA_HOST3=master03

	# master01 network interface name
	export K8SHA_NETINF1=ens32

	# master02 network interface name
	export K8SHA_NETINF2=ens32

	# master03 network interface name
	export K8SHA_NETINF3=ens32

	# keepalived auth_pass config
	export K8SHA_KEEPALIVED_AUTH=412f7dc3bfed32194d1600c483e10ad1d
	
	export K8SHA_IPS=(${K8SHA_IP1} ${K8SHA_IP2} ${K8SHA_IP3})
    	export K8SHA_HOSTS=(${K8SHA_HOST1} ${K8SHA_HOST2} ${K8SHA_HOST3})
    	export K8SHA_NETINF=ens32

	# kubernetes CIDR pod subnet
	export K8SHA_PODCIDR=10.10.0.0

	# kubernetes CIDR svc subnet
	export K8SHA_SVCCIDR=10.20.0.0
fi

##############################
# please do not modify anything below
##############################

mkdir -p ${HA_WORK_CONF_DIR}/{keepalived,haproxy}

cd ${HA_WORK_CONF_DIR}


# Create The Files
# k8s-keepalived.conf.tpl
# check_apiserver.sh
# haproxy.cfg.tpl
cp check_apiserver.sh.tpl keepalived
cp k8s-keepalived.conf.tpl keepalived
cp haproxy.cfg.tpl haproxy

# create all keepalived files
for i in `seq ${#K8SHA_IPS[@]}`
do
    mkdir -p ${K8SHA_HOSTS[i-1]}/{keepalived,haproxy}
    sed "s/##MASTER_IP##/${K8SHA_HOSTS[i-1]}/" keepalived/check_apiserver.sh.tpl > ${K8SHA_HOSTS[i-1]}/keepalived/check_apiserver.sh
    chmod u+x ${K8SHA_HOSTS[i-1]}/keepalived/check_apiserver.sh
    cp haproxy/haproxy.cfg.tpl ${K8SHA_HOSTS[i-1]}/haproxy/haproxy.cfg

    K8SHA_KA_PRIO=$((101-$i))

    sed \
        -e "s/K8SHA_KA_STATE/BACKUP/g" \
        -e "s/K8SHA_KA_INTF/${K8SHA_NETINF}/g" \
        -e "s/K8SHA_IPLOCAL/${K8SHA_IPS[i-1]}/g" \
        -e "s/K8SHA_KA_PRIO/${K8SHA_KA_PRIO}/g" \
        -e "s/K8SHA_VIP/${K8SHA_VIP}/g" \
        -e "s/K8SHA_KA_AUTH/${K8SHA_KEEPALIVED_AUTH}/g" \
        keepalived/k8s-keepalived.conf.tpl > ${K8SHA_HOSTS[i-1]}/keepalived/keepalived.conf
done

# SYNC The Files to the nodes and start HA
for i in ${MASTER_NAMES[@]}
do
	echo ">>> $i"
	ssh $i "mkdir -p /etc/{keepalived,haproxy} && yum install -y keepalived haproxy"
	scp ${i}/keepalived/* $i:/etc/keepalived
	scp ${i}/haproxy/* $i:/etc/haproxy
	ssh $i "systemctl enable --now haproxy keepalived"
done

