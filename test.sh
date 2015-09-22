#!/usr/bin/env bash

CURRENT_DIR=${PWD}
TMP_DIR=/tmp/ansible-test
mkdir -p $TMP_DIR 2> /dev/null

# Create hosts inventory
cat << EOF > $TMP_DIR/hosts
[webservers]
localhost ansible_connection=local
EOF

# Create group_vars for the webservers
mkdir -p $TMP_DIR/group_vars 2> /dev/null
cat << EOF > $TMP_DIR/group_vars/webservers
mysql_root_password: "i_am_root"
percona_install: true
mysql_benchmark_install: true

EOF

# Create Ansible config
cat << EOF > $TMP_DIR/ansible.cfg
[defaults]
roles_path = $CURRENT_DIR/../
host_key_checking = False
EOF

# Create playbook.yml
cat << EOF > $TMP_DIR/playbook.yml
---

- hosts: webservers
  gather_facts: yes
  sudo: yes

  roles:
    - ansible-mysql
EOF

export ANSIBLE_CONFIG=$TMP_DIR/ansible.cfg

# Syntax check
ansible-playbook $TMP_DIR/playbook.yml -i $TMP_DIR/hosts --syntax-check

# First run
ansible-playbook $TMP_DIR/playbook.yml -i $TMP_DIR/hosts

# Idempotence test
 ansible-playbook $TMP_DIR/playbook.yml -i $TMP_DIR/hosts | grep -q 'changed=0.*failed=0' \
 	&& (echo 'Idempotence test: pass' && exit 0) \
 	|| (echo 'Idempotence test: fail' && exit 1)

updatedb

sudo service mysql status
