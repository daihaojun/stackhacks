#!/usr/bin/env bash
# Filename:                mkimage.sh
# Description:             wrapper to triploe.sh
# Supported Langauge(s):   GNU Bash 4.2.x
# Time-stamp:              <2016-08-19 17:22:34 stack> 
# -------------------------------------------------------
export NODE_DIST=centos7
export USE_DELOREAN_TRUNK=1
export DELOREAN_TRUNK_REPO="http://buildlogs.centos.org/centos/7/cloud/x86_64/rdo-trunk-master-tripleo/"
export DELOREAN_REPO_FILE="delorean.repo"
export DIB_INSTALLTYPE_puppet_modules=source
export DIB_LOCAL_IMAGE=~/CentOS-7-x86_64-GenericCloud-1607.qcow2
export OS_PASSWORD=Redhat01

if [[ ! -f $DIB_LOCAL_IMAGE ]]; then
    echo "$DIB_LOCAL_IMAGE does not exist. Exiting."
    exit 1
fi

~/tripleo-ci/scripts/tripleo.sh --repo-setup
~/tripleo-ci/scripts/tripleo.sh --overcloud-images

