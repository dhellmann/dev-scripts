#!/usr/bin/env bash
set -xe

source logging.sh
source common.sh
source utils.sh
source ocp_install_env.sh
source hive_common.sh

# Delete the hive1 cluster resources.

override_vars_for_hive 1

ANSIBLE_FORCE_COLOR=true ansible-playbook \
    -e @vm_setup_vars.yml \
    -e @hive_vars.yml \
    -e "provisioning_network_name=${HIVE1_PROVISIONING_NETWORK_NAME}" \
    -e "baremetal_network_name=${HIVE1_BAREMETAL_NETWORK_NAME}" \
    -e "working_dir=$WORKING_DIR" \
    -e "num_masters=$HIVE1_NUM_MASTERS" \
    -e "num_workers=$HIVE1_NUM_WORKERS" \
    -e "extradisks=$VM_EXTRADISKS" \
    -e "virthost=$HOSTNAME" \
    -e "manage_baremetal=y" \
    -e "ironic_prefix=hive1_" \
    -i ${VM_SETUP_PATH}/inventory.ini \
    -b -vvv ${VM_SETUP_PATH}/teardown-playbook.yml

sudo rm -f /etc/NetworkManager/dnsmasq.d/${CLUSTER_NAME}.conf
# There was a bug in this file, it may need to be recreated.
# delete the interface as it can cause issues when not rebooting
sudo ifdown ${HIVE1_PROVISIONING_NETWORK_NAME} || true
sudo ip link delete ${HIVE1_PROVISIONING_NETWORK_NAME} || true
sudo rm -f /etc/sysconfig/network-scripts/ifcfg-${HIVE1_PROVISIONING_NETWORK_NAME}

# Leaving this around causes issues when the host is rebooted
# delete the interface as it can cause issues when not rebooting
sudo ifdown ${HIVE1_BAREMETAL_NETWORK_NAME} || true
sudo ip link delete ${HIVE1_BAREMETAL_NETWORK_NAME} || true
sudo rm -f /etc/sysconfig/network-scripts/ifcfg-${HIVE1_BAREMETAL_NETWORK_NAME}


# Delete the hive2 cluster resources.

override_vars_for_hive 2

ANSIBLE_FORCE_COLOR=true ansible-playbook \
    -e @vm_setup_vars.yml \
    -e @hive_vars.yml \
    -e "provisioning_network_name=${HIVE2_PROVISIONING_NETWORK_NAME}" \
    -e "baremetal_network_name=${HIVE2_BAREMETAL_NETWORK_NAME}" \
    -e "working_dir=$WORKING_DIR" \
    -e "num_masters=$HIVE2_NUM_MASTERS" \
    -e "num_workers=$HIVE2_NUM_WORKERS" \
    -e "extradisks=$VM_EXTRADISKS" \
    -e "virthost=$HOSTNAME" \
    -e "manage_baremetal=y" \
    -e "ironic_prefix=hive2_" \
    -i ${VM_SETUP_PATH}/inventory.ini \
    -b -vvv ${VM_SETUP_PATH}/teardown-playbook.yml

sudo rm -rf /etc/NetworkManager/dnsmasq.d/openshift.conf /etc/NetworkManager/conf.d/dnsmasq.conf /etc/yum.repos.d/delorean*
# There was a bug in this file, it may need to be recreated.
# delete the interface as it can cause issues when not rebooting
sudo ifdown ${HIVE2_PROVISIONING_NETWORK_NAME} || true
sudo ip link delete ${HIVE2_PROVISIONING_NETWORK_NAME} || true
sudo rm -f /etc/sysconfig/network-scripts/ifcfg-${HIVE2_PROVISIONING_NETWORK_NAME}

# Leaving this around causes issues when the host is rebooted
# delete the interface as it can cause issues when not rebooting
sudo ifdown ${HIVE2_BAREMETAL_NETWORK_NAME} || true
sudo ip link delete ${HIVE2_BAREMETAL_NETWORK_NAME} || true
sudo rm -f /etc/sysconfig/network-scripts/ifcfg-${HIVE2_BAREMETAL_NETWORK_NAME}
