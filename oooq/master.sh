#!/usr/bin/env bash
# Filename:                master.sh
# Description:             Sets up my dev env
# Supported Langauge(s):   GNU Bash 4.3.x
# Time-stamp:              <2017-01-10 23:14:51 jfulton> 
# -------------------------------------------------------
CLONEQ=0
RUNQ=1
DISK=1
IMG=1
SCRIPTS=1
# -------------------------------------------------------
export SSH_ENV=~/.quickstart/ssh.config.ansible
export VIRTHOST=$(hostname)

if [ $CLONEQ -eq 1 ]; then
    rm -rf ~/tripleo-quickstart/ 2> /dev/null
    git clone https://github.com/openstack/tripleo-quickstart
    ln -s ~/tripleo-quickstart/quickstart.sh 
fi    

if [ $RUNQ -eq 1 ]; then
    bash quickstart.sh --teardown nodes --release master-tripleo-ci -e @myconfigfile.yml $VIRTHOST    
fi

if [ $DISK -eq 1 ]; then
    bash run-add-disks.sh
fi

if [ $IMG -eq 1 ]; then
    bash overcloud-image-tweak.sh
fi

if [ $SCRIPTS -eq 1 ]; then
    tar cvfz scripts.tar.gz git-init.sh deploy.sh ironic-dns.sh wtf.sh tht/
    scp -F $SSH_ENV scripts.tar.gz stack@undercloud:/home/stack/
    ssh -F $SSH_ENV stack@undercloud "tar xf scripts.tar.gz"
fi
