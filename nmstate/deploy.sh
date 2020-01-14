#!/bin/bash -xe

basedir=$(dirname $0)

# https://github.com/kubevirt/cluster-network-addons-operator#deployment

oc apply -f ${basedir}/namespace.yaml
oc apply -f ${basedir}/network-addons-config.crd.yaml
oc apply -f ${basedir}/operator.yaml

# https://github.com/kubevirt/cluster-network-addons-operator#nmstate
# https://github.com/kubevirt/cluster-network-addons-operator#linux-bridge

oc apply -f ${basedir}/network-addons-config.yaml -n cluster-network-addons

oc wait networkaddonsconfig cluster --for condition=Available
