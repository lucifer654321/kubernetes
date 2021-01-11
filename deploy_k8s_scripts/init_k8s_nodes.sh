#!/bin/bash

SCRIPTS_DIR=$(cd "$(dirname "$0")"; pwd)
LOG_PATH="/var/log/init_nodes.log"

cd ${SCRIPTS_DIR}
source ./env/environment.sh &> ${LOG_PATH}

if [ ! ${ALL_IPS[0]} ];then
	ALL_IPS=(192.168.49.30 192.168.49.33 192.168.49.34 192.168.49.31 192.168.49.32)
	ALL_NAMES=(master01 master02 master03 k8snode01 k8snode02)
fi

HOST_File='/etc/hosts'
SSH_Conf='/etc/ssh/ssh_config'
Scripts_Update='init_1_update.sh'
Scripts_ipvs='init_2_ipvs.sh'
YUM_Dir='/etc/yum.repos.d'

yum install -y https://mirrors.aliyun.com/epel/epel-release-latest-8.noarch.rpm  &>> ${LOG_PATH}
sed -i 's|^#baseurl=https://download.fedoraproject.org/pub|baseurl=https://mirrors.aliyun.com|' ${YUM_Dir}/epel* &>> ${LOG_PATH}
sed -i 's|^metalink|#metalink|' ${YUM_Dir}/epel* &>> ${LOG_PATH}

# Setting hosts file
echo "#######################################"
echo "Setup HOSTS Files For the K8S Cluster"
echo "#######################################"

sed -i '3,$d' ${HOST_File} &>> ${LOG_PATH}

for i in `seq ${#ALL_IPS[@]}`
do
	echo "${ALL_IPS[i-1]}  ${ALL_NAMES[i-1]}" >> ${HOST_File}
done

# Setting Public Key For Login
echo "#######################################"
echo "Setup Public Key For Login without PWD"
echo "#######################################"

# sed -ri 's/^#(.*)ask/\1no/' ${SSH_Conf}
yum install -y sshpass wget &>> ${LOG_PATH}
yes | ssh-keygen -N "" -f /root/.ssh/id_rsa &>> ${LOG_PATH}

for i in ${ALL_NAMES[@]}
do
    sshpass -p"redhat" ssh-copy-id $i -o StrictHostKeyChecking=no
    echo "#### Setup Hostname ####"
    ssh $i "hostnamectl set-hostname $i"
    scp ${HOST_File} $i:${HOST_File}
    scp ${Scripts_Update} ${Scripts_ipvs} ${i}:/tmp/
done

echo ">>>>>>>>>>>>> Public Key Done <<<<<<<<<<<<<<"
echo

# Update the Kernel in all nodes
for i in ${ALL_NAMES[@]}
do
    echo ">>> $i"
    echo "#### Update Kernel in $i ####"
    ssh $i "bash /tmp/${Scripts_Update}"
    echo ">>>>>>>>> Update Kernel in $i Done! <<<<<<<<<<<<<<"
    echo
done

# Reboot
for i in ${ALL_NAMES[@]}
do
    ssh $i "echo '/bin/bash /tmp/${Scripts_ipvs}' >> /etc/bashrc"
    if [ $i != `hostname` ];then
        ssh $i reboot
    fi
done

reboot
