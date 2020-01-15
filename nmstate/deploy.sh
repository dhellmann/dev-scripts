#!/bin/bash -xe

basedir=$(dirname $0)

# https://github.com/kubevirt/cluster-network-addons-operator#deployment

oc apply -f https://raw.githubusercontent.com/kubevirt/cluster-network-addons-operator/master/manifests/cluster-network-addons/0.25.0/namespace.yaml

oc apply -f https://raw.githubusercontent.com/kubevirt/cluster-network-addons-operator/master/manifests/cluster-network-addons/0.25.0/network-addons-config.crd.yaml

oc apply -f https://raw.githubusercontent.com/kubevirt/cluster-network-addons-operator/master/manifests/cluster-network-addons/0.25.0/operator.yaml

# https://github.com/kubevirt/cluster-network-addons-operator#nmstate
# https://github.com/kubevirt/cluster-network-addons-operator#linux-bridge

oc apply -f ${basedir}/network-addons-config.yaml -n cluster-network-addons

oc wait networkaddonsconfig cluster --for condition=Available
