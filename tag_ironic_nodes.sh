#!/bin/bash
# Filename:                tag_ironic_nodes.sh
# Description:             tags ironic nodes directly
# Supported Langauge(s):   Ironic CLI 0.8.1 and GNU Bash 4.2.x
# Time-stamp:              <2016-02-05 10:14:50 jfulton> 
# -------------------------------------------------------
# This script tags nodes directly because ahc-tools is not in osp8
#   https://bugzilla.redhat.com/show_bug.cgi?id=1282580 
# This is a around. 
# -------------------------------------------------------
ironic node-list | grep available | while read junk line junk
do 
  memory=`ironic node-show $line| grep properties | awk '{print $5}' | sed -e "s/u'//" -e "s/',//"`
  #ironic node-show $line| grep properties | awk '{print $5}' | sed -e "s/u'//" -e "s/',//"
  echo "Memory: $memory"
  case $memory in
    "49152")
      echo "Control"
      ironic node-update $line replace properties/capabilities=profile:control,boot_option:local
    ;;
    "98304")
      echo "Compute"
      ironic node-update $line replace properties/capabilities=profile:compute,boot_option:local
    ;;
    "131072")
      echo "Ceph"
      ironic node-update $line replace properties/capabilities=profile:ceph-storage,boot_option:local
    ;;
  esac
done

echo "Ironic node properties have been set to the following:"
for ironic_id in $(ironic node-list | awk {'print $2'} | grep -v UUID | egrep -v '^$'); do echo $ironic_id; ironic node-show $ironic_id  | egrep "memory_mb|profile" ; echo ""; done

