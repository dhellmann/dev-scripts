#!/bin/bash -xe

# https://github.com/nmstate/kubernetes-nmstate/blob/master/docs/user-guide-state-reporting.md

oc get nodenetworkstates -o yaml $1
