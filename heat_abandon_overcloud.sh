# Filename:                heat_abandon_overcloud.sh
# Description:             Abandon's triple-o overcloud heatstack
# Supported Langauge(s):   Tested on: OSP7.3 
# Time-stamp:              <2016-03-18 08:38:28 jfulton> 
# -------------------------------------------------------
# When the following happens this script abandons an overcloud. 
# 
# [stack@hci-director ~]$ heat stack-list 
# +--------------------------------------+------------+---------------+----------------------+
# | id                                   | stack_name | stack_status  | creation_time        |
# +--------------------------------------+------------+---------------+----------------------+
# | 34632a75-ef45-4786-8610-bde1d084e77f | overcloud  | DELETE_FAILED | 2016-03-11T10:48:47Z |
# +--------------------------------------+------------+---------------+----------------------+
# [stack@hci-director ~]$ 

# See comment 3 for how to workaround it: 

#  https://bugzilla.redhat.com/show_bug.cgi?id=1234607
# -------------------------------------------------------
test "$(whoami)" != 'stack' && (echo "This must be run by the stack user on the undercloud"; exit 1)

source ~/stackrc

# 1. enable stack abandon
echo "Enabling stack abandon in /etc/heat/heat.conf"
sudo grep enable_stack_abandon /etc/heat/heat.conf
sudo sed -e s/\#enable_stack_abandon\ =\ false/enable_stack_abandon=true/ -i /etc/heat/heat.conf
sudo grep enable_stack_abandon /etc/heat/heat.conf
echo "Restarting Heat"
sudo systemctl restart openstack-heat-engine

# 2. abandon overcloud
echo "Abandoning overcloud (output saved to abandoned-overcloud.json)"
heat stack-abandon overcloud > abandoned-overcloud.json

# 3. manually cleanup overcloud
# a. nova
echo "Deleting nova instances independently of Heat"
for x in $(nova list | awk {'print $2'} | egrep -v 'ID|^$'); do nova delete $x; done 

# b. neutron ports
# neutron items to not delete
ctlplane_netid=$(neutron net-list | grep ctlplane | awk {'print $2'})
ctlplane_subnetid=$(neutron net-list | grep ctlplane |  awk {'print $6'})
echo "Will not delete netork resources connected to the ctlplane"
echo "ctlplane network id: $ctlplane_netid"
echo "ctlplane subnet id: $ctlplane_subnetid"

echo "Deleting neutron ports independently of Heat (preserving ctlplane)"
for x in $(neutron port-list | grep -v $ctlplane_subnetid | awk {'print $2'} | egrep -v 'id|^$'); do neutron port-delete $x; done 

# c. neutron subnets
echo "Deleting neutron subnets independently of Heat  (preserving ctlplane)"
for x in $(neutron subnet-list | grep -v $ctlplane_subnetid | awk {'print $2'} | egrep -v 'id|^$'); do neutron subnet-delete $x; done 

# d. neutron networks (all but ctlplane)
echo "Deleting neutron networks independently of Heat (preserving ctlplane)"
for x in $(neutron net-list | grep -v ctlplane | awk {'print $2'} | egrep -v 'id|^$'); do neutron net-delete $x; done 

echo "Give Heat time to complete the stack abandon"
