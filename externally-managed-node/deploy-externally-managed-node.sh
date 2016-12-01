source ~/stackrc
time openstack overcloud deploy --templates \
-r ~/custom-templates/custom_roles_data.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
-e ~/custom-templates/network.yaml \
-e ~/custom-templates/externally-managed.yaml 
