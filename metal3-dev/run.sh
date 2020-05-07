#!/bin/bash -xe

bindir=$(dirname $0)

source $bindir/../utils.sh

if ! which operator-sdk 2>&1 >/dev/null ; then
    echo "Did not find operator-sdk, set INSTALL_OPERATOR_SDK=1 in config_$USER.sh"
    exit 1
fi

if ! which yq 2>&1 >/dev/null ; then
    echo "Did not find yq"
    echo "Install with: pip3 install --user yq"
    exit 1
fi

bmo_path=$GOPATH/src/github.com/metal3-io/baremetal-operator
if [ ! -d $bmo_path ]; then
    echo "Did not find $bmo_path"
    exit 1
fi

# Scale the existing deployment down.
oc scale deployment -n openshift-machine-api --replicas=0 metal3

# Save a copy of the full deployment as input
oc get deployment -n openshift-machine-api -o yaml metal3 > $bindir/deployment-full.yaml

# Extract the containers list, skipping the bmo
cat $bindir/deployment-full.yaml \
    | yq -Y '.spec.template.spec.containers | map(select( .command[0] != "/baremetal-operator"))' \
         > $bindir/deployment-dev-containers.yaml

# Get a stripped down version of the deployment
cat $bindir/deployment-full.yaml \
    | yq -Y 'del(.spec.template.spec.containers) | del(.status) | del(.metadata.annotations) | del(.metadata.selfLink) | del(.metadata.uid) | del(.metadata.resourceVersion)' \
         > $bindir/deployment-dev-without-containers.yaml

# Combine the stripped down deployment with the container list
containers=$(cat $bindir/deployment-dev-containers.yaml | yq '.')
cat $bindir/deployment-dev-without-containers.yaml \
    | yq -Y --argjson containers "$containers" \
         'setpath(["spec", "template", "spec", "containers"]; $containers) | setpath(["metadata", "name"]; "metal3-development")' \
         > $bindir/deployment-dev.yaml

# Launch the deployment with the support services and ensure it is scaled up
oc apply -f $bindir/deployment-dev.yaml -n openshift-machine-api
oc scale deployment -n openshift-machine-api --replicas=1 metal3-development

# Set some variables the operator expects to have in order to work
export OPERATOR_NAME=baremetal-operator
export DEPLOY_KERNEL_URL=http://172.22.0.3:6180/images/ironic-python-agent.kernel
export DEPLOY_RAMDISK_URL=http://172.22.0.3:6180/images/ironic-python-agent.initramfs
export IRONIC_ENDPOINT=http://172.22.0.3:6385/v1/
export IRONIC_INSPECTOR_ENDPOINT=http://172.22.0.3:5050/v1/

# Wait for the ironic service to be available
wait_for_json ironic "$IRONIC_ENDPOINT" 300 \
              -H "Accept: application/json" -H "Content-Type: application/json"

# Run the operator
cd $bmo_path

# Use our local verison of the CRD, in case it is newer than the one
# in the cluster now.
oc apply -f deploy/crds/metal3.io_baremetalhosts_crd.yaml

operator-sdk run --local \
		     --watch-namespace=openshift-machine-api \
		     --operator-flags="-dev"
