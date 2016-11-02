# Filename:                rdo.sh
# Description:             Set up RDO dev env
# Supported Langauge(s):   GNU Bash 4.2.x 
# Time-stamp:              <2016-10-21 16:01:49 jfulton> 
# -------------------------------------------------------
# Automates the following for me: 
# - http://docs.openstack.org/developer/tripleo-docs/environments/environments.html#environment-setup
# - http://docs.openstack.org/developer/tripleo-docs/advanced_deployment/tripleo.sh.html
# -------------------------------------------------------
PKGS=0
NEW_IMG=0
GIT=0
REPOS=1
CLEAN_OLD_VMS=1
IMG=CentOS-7-x86_64-GenericCloud-1608.qcow2
# -------------------------------------------------------
if [ $PKGS -eq 1 ]; then
    # dependency: packages
    echo "Checking for necessary packages"

    if which wget ; then
	echo "wget is already installed"
    else
	echo "Installing wget"
	sudo yum install wget -y
    fi

    git review --version
    if [ $? -gt 0 ]; then
	echo "installing git-review from upstream"
	dir=/tmp/$(date | md5sum | awk {'print $1'})
	mkdir $dir
	pushd $dir
	wget ftp://195.220.108.108/linux/epel/7/x86_64/g/git-review-1.24-5.el7.noarch.rpm
	sudo yum localinstall git-review-1.24-5.el7.noarch.rpm -y 
	popd 
	rm -rf $dir
    fi    

    if which colordiff ; then
	echo "colordiff is already installed"
    else
	echo "Installing colordiff from upstream"
	dir=/tmp/$(date | md5sum | awk {'print $1'})
	mkdir $dir
	pushd $dir
	wget ftp://195.220.108.108/linux/epel/7/x86_64/c/colordiff-1.0.13-2.el7.noarch.rpm
	sudo yum localinstall colordiff-1.0.13-2.el7.noarch.rpm -y
	popd 
	rm -rf $dir
    fi

    if which ccze ; then
	echo "ccze is already installed"
    else
	echo "Installing ccze from upstream"
	dir=/tmp/$(date | md5sum | awk {'print $1'})
	mkdir $dir
	pushd $dir
	wget https://kojipkgs.fedoraproject.org/packages/ccze/0.2.1/11.el7/x86_64/ccze-0.2.1-11.el7.x86_64.rpm
	sudo yum localinstall ccze-0.2.1-11.el7.x86_64.rpm -y
	popd 
	rm -rf $dir
    fi

    if which reptyr ; then
	echo "reptyr is already installed"
    else
	echo "Installing reptyr from upstream"
	dir=/tmp/$(date | md5sum | awk {'print $1'})
	mkdir $dir
	pushd $dir
	wget https://dl.fedoraproject.org/pub/epel/7/x86_64/r/reptyr-0.5-1.el7.x86_64.rpm
	sudo yum localinstall reptyr-0.5-1.el7.x86_64.rpm -y
	popd 
	rm -rf $dir
    fi
fi
# -------------------------------------------------------
if [ $NEW_IMG -eq 1 ]; then
    # dependency: centos image
    if [[ ! -f $img ]] ; then
	echo "Need to get centos image" 
	wget http://cloud.centos.org/centos/7/images/$img.xz
	xz -d $img.xz
    fi
    if [[ ! -f $img ]] ; then
	echo "Could not get centos image"
	exit 1
    fi
fi
# -------------------------------------------------------
if [ $GIT -eq 1 ]; then
    echo "configuring git"
    git config --global user.name="John Fulton"
    git config --global user.email "fulton@redhat.com"
    git config --global gitreview.username fultonj
    git config user.editor "emacs"

    # git remote add gerrit ssh://fultonj@review.openstack.org:29418/openstack-dev/sandbox.git
    # git remote rm gerrit
    # git review -s
fi
# -------------------------------------------------------
if [ $REPOS -eq 1 ]; then
    # local repos 
    #sudo subscription-manager repos --enable=rhel-7-server-rpms \
	#     --enable=rhel-7-server-optional-rpms --enable=rhel-7-server-extras-rpms \
	#     --enable rhel-7-server-openstack-8-rpms
    # subscription-manager repos 
    # yum update

    sudo curl -L -o /etc/yum.repos.d/delorean.repo http://buildlogs.centos.org/centos/7/cloud/x86_64/rdo-trunk-master-tripleo/delorean.repo

    sudo curl -L -o /etc/yum.repos.d/delorean-current.repo http://trunk.rdoproject.org/centos7/current/delorean.repo
    sudo sed -i 's/\[delorean\]/\[delorean-current\]/' /etc/yum.repos.d/delorean-current.repo
    sudo /bin/bash -c "cat <<EOF>>/etc/yum.repos.d/delorean-current.repo

includepkgs=diskimage-builder,instack,instack-undercloud,os-apply-config,os-cloud-config,os-collect-config,os-net-config,os-refresh-config,python-tripleoclient,tripleo-common,openstack-tripleo-heat-templates,openstack-tripleo-image-elements,openstack-tripleo,openstack-tripleo-puppet-elements,openstack-puppet-modules
EOF"


    sudo curl -L -o /etc/yum.repos.d/delorean-deps.repo http://trunk.rdoproject.org/centos7/delorean-deps.repo

    sudo yum repolist

    sudo yum install -y instack-undercloud
fi

# -------------------------------------------------------
if [ $CLEAN_OLD_VMS -eq 1 ]; then
    for vm in $(sudo virsh list --all | egrep "baremetalbrbm|instack" | awk {'print $2'});
    do
	echo "Delting VM: $vm"
	sudo virsh destroy $vm
	sudo virsh undefine $vm
    done
fi
# -------------------------------------------------------

export NODE_DIST=centos7
export DIB_LOCAL_IMAGE=$IMG
export NODE_COUNT=2
export TESTENV_ARGS="--baremetal-bridge-names 'brbm brbm1 brbm2'"

# overcloud VMs
export NODE_CPU=2
export NODE_MEM=8192
export NODE_DISK=40

# undercloud VM
#export UNDERCLOUD_NODE_CPU=2
export UNDERCLOUD_NODE_CPU=4
#export UNDERCLOUD_NODE_MEM=6144
export UNDERCLOUD_NODE_MEM=11264
#export UNDERCLOUD_NODE_DISK=30
export UNDERCLOUD_NODE_DISK=40

instack-virt-setup

# -------------------------------------------------------
echo "Configuring ~/.ssh/config to not prompt for non-matching keys and not manage keys via known_hosts"
cat /dev/null > ~/.ssh/config
echo "StrictHostKeyChecking no" >> ~/.ssh/config
echo "UserKnownHostsFile=/dev/null" >> ~/.ssh/config
echo "LogLevel ERROR" >> ~/.ssh/config
chmod 0600 ~/.ssh/config
chmod 0700 ~/.ssh/
# -------------------------------------------------------

echo "add instack to /etc/hosts"
echo "scp $IMG to instack VM"
# scp CentOS-7-x86_64-GenericCloud-1607.qcow2 root@instack:/tmp
echo "ssh root@instack # set a password for stack"
echo "ssh -A stack@instack "
echo "sudo yum install git-review -y"
echo "config git on instack VM"
echo -e "
  git config --global user.email fulton@redhat.com
  git config --global gitreview.username fultonj
  git config --list
  git clone https://git.openstack.org/openstack-infra/tripleo-ci.git 
  cd tripleo-ci
  git remote add gerrit ssh://fultonj@review.openstack.org:29418/openstack-infra/tripleo-ci.git
"
echo "Follow the tripleo.sh document: "
echo " http://docs.openstack.org/developer/tripleo-docs/advanced_deployment/tripleo.sh.html"


# ssh root@192.168.122.251

echo "Remember to run the image"
echo " export DIB_LOCAL_IMAGE=$IMG"
echo "tripleo-ci/scripts/tripleo.sh --overcloud-images"
