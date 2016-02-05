# Filename:                balance_placement_groups.sh
# Description:             inceases pg_num and pgp_num
# Supported Langauge(s):   Bash 4.2.x and Ceph CLI 0.94.1
# Time-stamp:              <2016-02-05 07:46:05 jfulton> 
# -------------------------------------------------------
# This script should be run on one of the OSDs
# 
# This is a workaround for:
#  https://bugzilla.redhat.com/show_bug.cgi?id=1252546
# 
# Each pool has two properties that dictate its number of placement
# groups: pg_num and pgp_num (number of PGs for placement on OSD.) 
# Manually inceases pg_num and pgp_num to Ceph recommendations.
# -------------------------------------------------------
pg_num=256
pgp_num=256

echo "You may wish run 'ceph -w' in a separate terminal"

echo "Ceph Health Before"
ceph osd lspools
ceph pg stat
ceph health

echo "Increasing pg_num to $pg_num and pgp_num to $pgp_num"

for i in rbd images volumes vms; do
 ceph osd pool set $i pg_num $pg_num;
 sleep 10
 ceph osd pool set $i pgp_num $pgp_num;
 sleep 10
done

echo "Ceph Health After"
ceph osd lspools
ceph pg stat
ceph health
