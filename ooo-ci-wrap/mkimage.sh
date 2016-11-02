#!/usr/bin/env bash
# Filename:                mkimage.sh
# Description:             wrapper to tripleo.sh
# Supported Langauge(s):   GNU Bash 4.2.x
# Time-stamp:              <2016-08-19 19:05:48 stack> 
# -------------------------------------------------------
CLEAN=1
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

if [ $CLEAN -eq 1 ]; then
    sudo rm -f ~/overcloud-full.{vmlinuz,initrd,qcow2}
    sudo rm -f ~/ironic-python-agent.{vmlinuz,initrd,qcow2}
    sudo rm -f /httpboot/agent.kernel
    sudo rm -f /httpboot/agent.ramdisk
fi

~/tripleo-ci/scripts/tripleo.sh --repo-setup
#~/tripleo-ci/scripts/tripleo.sh --overcloud-images

