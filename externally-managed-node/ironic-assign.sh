# Filename:                ironic-assign.sh
# Description:             Assign ironic nodes as ext mgm'd
# Supported Langauge(s):   GNU Bash 4.2.x
# Time-stamp:              <2016-11-10 18:01:23 jfulton> 
# -------------------------------------------------------
name=externally-managed

if [[ $# -eq 0 ]] ; then
    echo "Please pass a regex matching the nodes to be tagged; e.g. \"u33|u35\""
    exit 1
fi
regex=$1

source ~/stackrc
echo "Assigning nodes from ironic's list that match $regex"
# The 10.19.136.2{6,7,8} IPs below are for the IPMI addresses
for id in $(ironic node-list | grep available | awk '{print $2}'); do
    match=0;
    match=$(ironic node-show $id | egrep $regex | wc -l);
    if [[ $match -gt 0 ]]; then
	echo $id;
    fi
done > /tmp/n_nodes

count=$(cat /tmp/n_nodes | wc -l)
echo "$count nodes match $regex"

i=0
for id in $(cat /tmp/n_nodes); do
    node="$name-$i"
    ironic node-update $id replace properties/capabilities=node:$node,boot_option:local
    i=$(expr $i + 1)
done

echo "Ironic node properties have been set to the following:"
for ironic_id in $(ironic node-list | awk {'print $2'} | grep -v UUID | egrep -v '^$');
do
    echo $ironic_id;
    ironic node-show $ironic_id  | egrep -A 1 "memory_mb|profile|wwn" ;
    echo "";
done
