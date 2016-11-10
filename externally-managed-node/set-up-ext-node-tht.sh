#!/usr/bin/env bash
# Filename:                set-up-ext-node-tht.sh
# Description:             Creates THT override directory
# Supported Langauge(s):   GNU Bash 4.2.x
# Time-stamp:              <2016-11-10 17:09:41 jfulton> 
# -------------------------------------------------------
roles=/usr/share/openstack-tripleo-heat-templates/roles_data.yaml
role=./externally-managed-role.yaml
param=./externally-managed.yaml
for f in $role $param $roles; do 
    if [[ ! -f $f ]]; then
	echo "$f is missing. Exiting."
	echo "Either install THT or run this script in it's repo directory"
	exit 1
    fi
done

dir=~/custom-templates
if [[ ! -d $dir ]]; then
    mkdir ~/custom-templates
fi

# concatenate externally manged role into the full list of roles
cp -f $roles $dir/custom_roles_data.yaml
cat $role >> $dir/custom_roles_data.yaml

cp $param $dir

cp ./deploy-externally-managed-node.sh ~/
