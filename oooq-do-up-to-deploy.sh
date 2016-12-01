#!/usr/bin/env bash
# Filename:                do-up-to-deply.sh
# Description:             finishes undercloud prep 
# Supported Langauge(s):   GNU Bash 4.3.x
# Time-stamp:              <2016-12-01 14:25:27 jfulton> 
# -------------------------------------------------------
# tripleo-quickstart says to follow this doc when it's done
#   http://ow.ly/c44w304begR
# This script does that, up to the overcloud deploy.
# -------------------------------------------------------
source ~/stackrc

echo "uploading images to glance"
openstack overcloud image upload

echo "importing list of virtual hardware into ironic"
openstack baremetal import instackenv.json

echo "introspecing nodes"
openstack baremetal introspection bulk start

echo "Setting DNS Server"
neutron subnet-list
SNET=$(neutron subnet-list | awk '/192/ {print $2}')
neutron subnet-show $SNET
neutron subnet-update ${SNET} --dns-nameserver 192.168.1.1 --dns-nameserver 8.8.8.8 --dns-nameserver 8.8.4.4
neutron subnet-show $SNET

echo "To deploy one controller node run: "
echo ""
echo "  time openstack overcloud deploy --templates --compute-scale 0"
echo ""
echo "It can then be tested with: "
echo "  source overcloudrc"
echo "  openstack token issue"
