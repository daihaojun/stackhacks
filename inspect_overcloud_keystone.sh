# Filename:                inspect_overcloud_keystone.sh
# Description:             Attempts to rest overcloud admin password
# Supported Langauge(s):   GNU Bash 4.2.x and openstack 1.7.1
# Time-stamp:              <2016-08-11 11:06:33 jfulton> 
# -------------------------------------------------------
# This does not actually reset the password. 
# It is handy for investigating a broken install. 
# 
# Uses ideas from:
# http://adam.younglogic.com/2015/03/troubleshoot-new-keystone/
# -------------------------------------------------------
echo "
     Attempting to SSH into a controller node to get the admin token
     Will then try to use that token to list keystone users, roles and projects.
"

PUBLIC_API_IP_PREFIX=10.19.139
CTRL_IP=`nova list |  grep controller | awk {'print $12'} | sed s/ctlplane=//g | head -1`
if [ -z "$CTRL_IP" ]; then echo "Cannot overcloud determine controller IP"; exit 0; fi 
ADMIN_TOKEN=`ssh heat-admin@$CTRL_IP "sudo grep admin_token /etc/keystone/keystone.conf" | awk '{print $3}' | grep -v ADMIN | tail -1`
echo "Looking for Keystone IP"
for ip in `nova list |  grep controller | awk {'print $12'} | sed s/ctlplane=//g`; do 
    KEYSTONE_IP=`ssh heat-admin@$ip "sudo ip a | grep $PUBLIC_API_IP_PREFIX | grep 32" | awk {'print $2'} | sed 's/\/32//g'`
    echo "Does $ip have it?...."
    if [ -n "$KEYSTONE_IP" ]; then echo "found $KEYSTONE_IP"; break; fi 
    echo "Still looking"
done;

USERS=`openstack --os-token $ADMIN_TOKEN --os-url http://$KEYSTONE_IP:35357/v2.0/ user list`
if [ -z "$USERS" ]; then echo "ERROR: The overcloud has no users to set a password for."; fi 

ROLES=`openstack --os-token $ADMIN_TOKEN --os-url http://$KEYSTONE_IP:35357/v2.0/ role list`
if [ -z "$ROLES" ]; then echo "ERROR: The overcloud has no roles "; fi 

PROJECTS=`openstack --os-token $ADMIN_TOKEN --os-url http://$KEYSTONE_IP:35357/v2.0/ project list`
if [ -z "$PROJECTS" ]; then echo "ERROR: The overcloud has no projects "; fi 

echo "Is admin in the admin project?"
openstack --os-token $ADMIN_TOKEN --os-url http://$KEYSTONE_IP:35357/v2.0/ user role list --project admin admin

echo "You can try to fix it using: http://docs.openstack.org/cli-reference/openstack.html"
