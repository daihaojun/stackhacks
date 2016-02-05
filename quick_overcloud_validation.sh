#!/bin/bash -x

echo "update FLOAT_START/FLOAT_END range based on jj-*"
echo "update the "cinder create" and "nova volume-list" commands for osp8"
exit 1

myIP=$(host `hostname` | awk '{print $4}')

echo 'This system ip: ', $myIP

export KEYSTONE_IP=$myIP

export DEMO_CIDR="10.0.5.0/24"

export FLOAT_START=10.19.139.168
export FLOAT_END=10.19.139.169

source ~/overcloudrc
KEYSTONE_PUB_IP=`echo $OS_AUTH_URL | awk -F/ '{print $3}' | awk -F: '{print $1}'`

# create demo environment
#keystone user-create --name demo --pass demo
#keystone tenant-create --name demo-tenant
#keystone user-role-add --user-id demo --tenant-id demo-tenant --role-id _member_
openstack user create --password demo demo
openstack project create demo-tenant
openstack role add --user demo --project demo-tenant _member_
#keystone user-role-add --user-id demo --tenant-id demo-tenant --role-id Member
cat > ~/keystonerc_demo << EOF
export OS_USERNAME=demo
export OS_TENANT_NAME=demo-tenant
export OS_PASSWORD=demo
export OS_AUTH_URL=http://${KEYSTONE_PUB_IP}:35357/v2.0/
export PS1='[\u@\h \W(demo_member)]\$ '
EOF
source ~/keystonerc_demo
env | grep OS_

# import image
#glance image-create --name rhel65u --is-public true --disk-format qcow2 --container-format bare --file /pub/projects/rhos/common/images/rhel-guest-image-6-6.5-20131115.0-1.qcow2.unlock
glance image-create --name rhel65u --disk-format qcow2 --container-format bare --file /pub/projects/rhos/common/images/rhel-guest-image-6-6.5-20131115.0-1.qcow2.unlock
glance image-list

# create network
neutron net-list
neutron net-create net1
neutron subnet-create --name demo-tenant-subnet net1 ${DEMO_CIDR}
neutron router-create router1
subID=$(neutron subnet-list | awk "/demo-tenant-subnet/ {print \$2}")
neutron router-interface-add router1 $subID

# get ID for default security group in demo tenant

for i in $(neutron security-group-list | awk ' /default/ { print $2 } ')
do 
  # add ssh and icmp to default security groups
  neutron security-group-rule-create --direction ingress --protocol icmp  $i
  neutron security-group-rule-create --direction ingress --protocol tcp --port_range_min 22 --port_range_max 22 $i
  neutron security-group-show $i
done

# boot instance
nova keypair-add demokp > ~/demokp.pem
chmod 600 ~/demokp.pem 
nova boot --flavor 2 --image rhel65u --key-name demokp inst1
nova boot --flavor 2 --image rhel65u --key-name demokp inst2

while [[ $(nova list | grep BUILD) ]]
do
  sleep 2
done
nova list
#nova get-vnc-console inst1  novnc
#nova get-vnc-console inst2  novnc

source overcloudrc

neutron net-create ext-net --router:external
neutron subnet-create --name public --gateway 10.19.143.254 --allocation-pool start=${FLOAT_START},end=${FLOAT_END} ext-net 10.19.136.0/21 
netid=$(neutron net-list | awk "/ext-net/ { print \$2 }")

neutron router-gateway-set router1 ${netid}

source ~/keystonerc_demo
instid=$(nova list | awk '/inst1 / {print $2}')
portid=$(neutron port-list --device_id ${instid} | awk '/ip_address/ {print $2}') 

neutron floatingip-create --port-id $portid ext-net
float_ip=$(nova floating-ip-list | awk '/10\.19/ {print $4}')
sleep 30
ssh -i ~/demokp.pem cloud-user@$float_ip uptime

# ping instance 2 from instance 1
inst2_ip=$(nova show inst2 | awk ' /net1/ { print $5 } ' | cut -f1 -d,)
echo -e "inst2_ip: $inst2_ip"
ssh -i ~/demokp.pem cloud-user@$float_ip ping -c 3 $inst2_ip

# create a volume
cinder create --display-name test 1
sleep 15
volid=$(nova volume-list | awk ' /test/ { print $2 } ')
echo -e "volid = $volid"

# attach the volume to inst1
volname=$(basename $(nova volume-attach inst1 $volid auto | awk ' /device/ { print $4 } '))
sleep 15
ssh -i ~/demokp.pem cloud-user@$float_ip grep $volname /proc/partitions

