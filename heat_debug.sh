#!/bin/bash 
# Filename:                heat_debug.sh
# Description:             Gathers Heat Debug info
# Supported Langauge(s):   GNU Bash 4.2.x and Heat 0.8.0
# Time-stamp:              <2016-09-12 10:27:26 jfulton> 
# -------------------------------------------------------
# Gets heat deployment-show data as described in: 
#  http://hardysteven.blogspot.com/2015/04/debugging-tripleo-heat-templates.html
# 
# Commits horrible string hacks to unpack the embedded error
# into a log file to make debugging a little easier. 
# -------------------------------------------------------
function show_details {
    for id in `cat /tmp/failed_heat_zero_ids`; do
	openstack software deployment show $id > /tmp/heat-$id 2> /dev/null
	#echo "Saved a 'heat deployment-show' output to /tmp/heat-$id"
	# very nasty hack...
	py_hack=/tmp/heat-$id.py
	py_count=$(grep deploy_stdout /tmp/heat-$id | wc -l)
	if [[ $py_count -gt 0 ]]; then 
	    echo "Converting output into Python new line hack: $py_hack"
	    echo -n "d = {" > $py_hack
	    grep deploy_stdout /tmp/heat-$id  >>  $py_hack
	    echo "}" >> $py_hack
	    echo "" >> $py_hack
	    echo "print d['deploy_stdout']" >> $py_hack
	    # ... uggggghhh ....
	    python $py_hack | sed -e s/'u001b'//g -e s/'\\/'/g -e s/'\[0m'//g -e s/'\[m'//g  > /tmp/heat-$id.log 
	    echo -e "#Try: \n\tcat /tmp/heat-$id.log | ccze -A | less -R \n"
	else
	    echo -e "#Try: \n\tcat /tmp/heat-$id | ccze -A | less -R \n"
	fi
    done 
}

case "$1" in
    --all)
	openstack stack resource list  --nested-depth 5 overcloud | grep FAILED | awk {'print $4'} > /tmp/failed_heat_zero_ids	
        ;;
    *)
	openstack stack resource list  --nested-depth 5 overcloud | grep FAILED | grep " 0 " | awk {'print $4'} > /tmp/failed_heat_zero_ids
esac

count=$(wc -l /tmp/failed_heat_zero_ids | awk {'print $1'})
echo "#$count results"

if [[ $count -gt 0 ]]; then
    show_details
fi
