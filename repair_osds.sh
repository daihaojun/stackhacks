# Filename:                repair_osds.sh
# Description:             Workaround for likely bug
# Supported Langauge(s):   Bash 4.2.x and Ceph CLI 0.94.1
# Time-stamp:              <2016-02-05 07:35:40 jfulton> 
# -------------------------------------------------------
# Run this on each of your OSD nodes. 
# 
# Director for OSP7 and OSP8 seems to have a bug where if 
# you are redploying on top of hardware that has previously 
# hosted an OSD then it is possible for the old FSID to 
# linger. If this happens then a deployment may have no 
# OSDs and when investigating you may see the following 
# error:
# 
# [root@overcloud-cephstorage-0 ~]# ceph-disk list
# /dev/sda :
#  /dev/sda1 other, iso9660
#  /dev/sda2 other, xfs, mounted on /
# /dev/sdb :
#  /dev/sdb1 ceph data, prepared, unknown cluster 7756567c-97d6-11e5-8cf3-52540089f28a, osd.11, journal /dev/sdn4
# /dev/sdc :
#  /dev/sdc1 ceph data, prepared, unknown cluster 7756567c-97d6-11e5-8cf3-52540089f28a, osd.5, journal /dev/sdn1
# /dev/sdd :
# ...
# [root@overcloud-cephstorage-0 ~]#
# 
# I have what might be a fix but it did not work on my first 
# test run and I need to deprioritize it right now. 
# 
# https://github.com/fultonj/puppet-ceph/commit/fe1d86439f07adabbda1fbf9cd98cf14b7813921
# 
# Since I am going to be deloying the HCI refarch using 
# ceph ansible I am only using this a few times as I get 
# OSP8 running with Ceph deployed by Puppet from Director. 
# -------------------------------------------------------

fsid=$(hiera ceph::profile::params::fsid)
ceph-disk list | grep "unknown cluster" | awk '{print $1 " " $10}' > /tmp/osd2jnl
cat /tmp/osd2jnl | while read osd jnl; do 
    echo "----------- start ----------- "
    echo "Setting the FSID of OSD: $osd and Jounal: $jnl to $fsid";
    ceph-disk prepare --cluster ceph --cluster-uuid $fsid --fs-type xfs $osd $jnl;
    sleep 5;
    ceph-disk activate $osd;
    sleep 5;
    ceph-disk activate-journal $jnl;
    sleep 5;
    echo "----------- finish ----------- "
done
