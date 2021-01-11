#!/bin/bash
# 2020年12月12日
# Auto Deploy HA With KeepAlived+HAProxy
# BY: Lucifer
########################################

#################################
#           部署高可用          #
#################################

if [ ${SCRIPTS_DIR} == "" ];then
	SCRIPTS_DIR=$(cd ..; pwd)
fi
source ${SCRIPTS_DIR}/env/directory_set.sh

HA_WORK_CONF_DIR="${WORK_DIR}/conf/ha"

mkdir -p ${HA_WORK_CONF_DIR}

cd ${HA_WORK_CONF_DIR}
echo "#### Install Keepalived & HAProxy ####"

# 创建haproxy配置文件

cat > haproxy.cfg.tpl <<EOF
global
  maxconn  2000
  ulimit-n  16384
  log  127.0.0.1 local0 err
  stats timeout 30s

defaults
  log global
  mode  http
  option  httplog
  timeout connect 5000
  timeout client  50000
  timeout server  50000
  timeout http-request 15s
  timeout http-keep-alive 15s

frontend k8s-master
  bind 0.0.0.0:16443
  bind 127.0.0.1:16443
  mode tcp
  option tcplog
  tcp-request inspect-delay 5s
  default_backend k8s-master

backend k8s-master
  mode tcp
  option tcplog
  option tcp-check
  balance roundrobin
  default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
  server ${MASTER_NAMES[0]}   ${MASTER_IPS[0]}:6443  check
  server ${MASTER_NAMES[1]}   ${MASTER_IPS[1]}:6443  check
  server ${MASTER_NAMES[2]}   ${MASTER_IPS[2]}:6443  check
EOF


MASTER_NUM=`echo ${#MASTER_IPS[@]}`

if [ ${MASTER_NUM} -gt 3 ];then
	for i in `seq 4 ${MASTER_NUM}`
	do
		echo "  server ${MASTER_NAMES[i-1]}   ${MASTER_IPS[i-1]}:6443  check" >> haproxy.cfg.tpl
	done
fi

# 创建keepalived配置文件模板
cat > k8s-keepalived.conf.tpl <<EOF
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
    script_user root
    enable_script_security
}
vrrp_script chk_apiserver {
    script "/etc/keepalived/check_apiserver.sh"
    interval 10
    weight -5
    fall 3  
    rise 2
}
vrrp_instance VI_1 {
    state K8SHA_KA_STATE
    interface K8SHA_KA_INTF
    mcast_src_ip K8SHA_IPLOCAL
    virtual_router_id 51
    priority K8SHA_KA_PRIO
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass K8SHA_KA_AUTH
    }
    virtual_ipaddress {
        K8SHA_VIP
    }
    track_script {
      chk_apiserver 
    }
}
EOF

# 创建健康检查脚本
cat > check_apiserver.sh.tpl <<EOF
#!/bin/bash

err=0
for k in \$(seq 1 5)
do
    check_code=\$(curl -k -s https://##MASTER_IP##:6443/healthz --cacert /etc/kubernetes/pki/ca.pem --cert /etc/kubernetes/pki/admin.pem --key /etc/kubernetes/pki/admin-key.pem)
    if [[ \${check_code} != "ok" ]]; then
        err=\$(expr \$err + 1)
        sleep 1
        continue
    else
        err=0
        break
    fi
done

if [[ \$err != "0" ]]; then
    echo "systemctl stop keepalived"
    /usr/bin/systemctl stop keepalived
    exit 1
else
    exit 0
fi
EOF
