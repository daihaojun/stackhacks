#!/usr/bin/env bash
# Filename:                mkundercloud.sh
# Description:             Sets up a virtual undercloud
# Supported Langauge(s):   GNU Bash 4.2.x
# Time-stamp:              <2016-08-19 22:46:13 jfulton> 
# -------------------------------------------------------
# Wrapper for: 
#  http://docs.openstack.org/developer/tripleo-docs/environments/environments.html
# 
# Assumes pre-req is done and that we're on step 4 (enable repos)
# -------------------------------------------------------
# Sets env variables to build instack VM and overcloud virtaul hardware
export DIB_LOCAL_IMAGE=~/CentOS-7-x86_64-GenericCloud-1607.qcow2

export OS_PASSWORD=Redhat01

export NODE_DIST=centos7
export USE_DELOREAN_TRUNK=1
export DELOREAN_TRUNK_REPO="http://buildlogs.centos.org/centos/7/cloud/x86_64/rdo-trunk-master-tripleo/"
export DELOREAN_REPO_FILE="delorean.repo"
export DIB_INSTALLTYPE_puppet_modules=source

export NODE_COUNT=2
export NODE_CPU=2
export NODE_MEM=5120
export NODE_DISK=40

export UNDERCLOUD_NODE_CPU=4
export UNDERCLOUD_NODE_MEM=11264
export UNDERCLOUD_NODE_DISK=100

# -------------------------------------------------------
# Delete old instack-*.qcow2 and machine from virsh
CLEAN=1

# Sets up repos if desired
DELOREAN=0
JEWL=0
QEMU=0
# -------------------------------------------------------
test "$(whoami)" != 'stack' \
    && (echo "This must be run by the stack user on a hypervisor"; exit 1)
# -------------------------------------------------------
if [ $CLEAN -eq 1 ]; then
    sudo virsh destroy instack
    sudo virsh undefine instack
    for vm in $(sudo virsh list --all | grep baremetal | awk {'print $2'}); do
	sudo virsh destroy $vm
	sudo virsh undefine $vm
    done;
    sudo rm -f ~/instack-*.qcow2 
fi
# -------------------------------------------------------
if [ $JEWL -eq 1 ]; then
    echo "Attempting to use RHEL to build CentOS image"
    echo "need to subscribe to repos and make up for small distro differences"

    echo "Installing repositories for CentOS Storage SIG: Ceph Jewel"
    # these change too often, so I will test them and only install what works
    curl https://raw.githubusercontent.com/CentOS-Storage-SIG/centos-release-ceph-jewel/master/CentOS-Ceph-Jewel.repo > /tmp/CentOS-Ceph-Jewel.repo
    full_repos=/tmp/CentOS-Ceph-Jewel.repo
    working_repos=/etc/yum.repos.d/CentOS-Ceph-Jewel.repo
    sudo rm -f $working_repos

    for url in $(grep baseurl $full_repos | sed -e s/baseurl=//g); do
	# which of these URLs actually work?
	real_url=$(echo $url | sed -e s/\$releasever/7/ -e s/\$basearch/x86_64/)
	HTTP_STATUS=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' $real_url)
	if [[ $HTTP_STATUS -eq 200 ]]; then
	    echo "Working: $real_url"
	    grep $url $full_repos -B 2 -A 3 >> /tmp/foo
	fi
    done
    sudo mv /tmp/foo $working_repos
    # deal with 7server (rhel version of $releasever) vs 7 (centos version of $releasever)
    sudo sed -i -e s/\$releasever/7/ $working_repos
    sudo sed -i -e 's%gpgcheck=.*%gpgcheck=0%' $working_repos
    sudo sed -i -e 's%enabled=.*%enabled=1%' $working_repos
fi
# -------------------------------------------------------
if [ $QEMU -eq 1 ]; then
    echo "Installing repositories for CentOS Virt SIG"
    tmpfile=$(mktemp)
    echo "[centos-virt-sig]" >> $tmpfile
    echo "name=CentOS-7 - Virt-SIG" >> $tmpfile
    echo "baseurl=http://mirror.centos.org/centos-7/7/virt/\$basearch/kvm-common/"  >> $tmpfile
    echo "gpgcheck=0" >> $tmpfile
    echo "enabled=1" >> $tmpfile
    echo "gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virt" >> $tmpfile
    sudo mv $tmpfile /etc/yum.repos.d/CentOS-Virt.repo
    
fi
# -------------------------------------------------------
if [ $DELOREAN -eq 1 ]; then
    echo "Enable last known good RDO Trunk Delorean repository for core openstack packages"
    sudo curl -L -o /etc/yum.repos.d/delorean.repo http://buildlogs.centos.org/centos/7/cloud/x86_64/rdo-trunk-master-tripleo/delorean.repo

    echo "Enable latest RDO Trunk Delorean repository only for the TripleO packages"

    sudo curl -L -o /etc/yum.repos.d/delorean-current.repo http://trunk.rdoproject.org/centos7/current/delorean.repo
    sudo sed -i 's/\[delorean\]/\[delorean-current\]/' /etc/yum.repos.d/delorean-current.repo
    sudo /bin/bash -c "cat <<EOF>>/etc/yum.repos.d/delorean-current.repo

includepkgs=diskimage-builder,instack,instack-undercloud,os-apply-config,os-cloud-config,os-collect-config,os-net-config,os-refresh-config,python-tripleoclient,openstack-tripleo-common,openstack-tripleo-heat-templates,openstack-tripleo-image-elements,openstack-tripleo,openstack-tripleo-puppet-elements,openstack-puppet-modules,puppet-*
EOF"

    echo "Enable the Delorean Deps repository"
    sudo curl -L -o /etc/yum.repos.d/delorean-deps.repo http://trunk.rdoproject.org/centos7/delorean-deps.repo
fi

# -------------------------------------------------------
rpm -q instack-undercloud
if [[ $? -eq 0 ]]; then
    echo "Need to install instack-undercloud"
    sudo yum install -y instack-undercloud
fi
# -------------------------------------------------------
if [[ ! -f $DIB_LOCAL_IMAGE ]]; then
    echo "$DIB_LOCAL_IMAGE does not exist. Exiting."
    exit 1
fi
# -------------------------------------------------------
echo "-------------------"
echo "Buidling instack"
echo "-------------------"
instack-virt-setup

IP=$(ip n | grep $(tripleo get-vm-mac " instack ") | awk '{print $1;}')
if [ $? -gt 0 ]; then
    echo "Error: Unable to get IP address of new instack VM"
    sudo virsh list --all
    exit 1
fi
echo "Updating /etc/hosts with new instack IP: $IP"
sudo sed -i -e "s/.*instack//g" /etc/hosts
sudo sh -c "echo \"$IP       instack\"    >> /etc/hosts"

echo "Virtual servers for ironic:"
sudo virsh list --all | grep baremetal

ssh root@$IP "cp /root/.ssh/authorized_keys /home/stack/.ssh/authorized_keys ; chown stack:stack /home/stack/.ssh/authorized_keys; chcon unconfined_u:object_r:ssh_home_t:s0 /home/stack/.ssh/authorized_keys"

ssh -A stack@$IP "echo 'git clone git@github.com:fultonj/stackhacks.git' >> sh_me"

echo "ssh -A stack@instack"


