#!/bin/bash
# 2021年1月12日
# Auto Create random key for token and encryption_key befor you run ansible-playbook
# By: Lucifer
#######################################################################################

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')
# BOOTSTRAP_TOKEN=$(head -c 6 /dev/urandom | md5sum | head -c 6)"."$(head -c 16 /dev/urandom | md5sum | head -c 16)

sed -ri "/^bootstrap_token:/cbootstrap_token: \'${BOOTSTRAP_TOKEN}\'" group_vars/all.yml
sed -ri "/^ENCRYPTION_KEY:/cENCRYPTION_KEY: \'${ENCRYPTION_KEY}\'" group_vars/all.yml
