# Externally Managed Node

This is an example TripleO custom role that has all of the services
that any TripleO node has but no additional configuration because that
additional configuration is provided by tools outside of TripleO.

## Files

- set-up-ext-node-tht.sh
  Runs a shell script to put THT and scripts in place to deploy this
  type of node. 

- externally-managed-role.yaml
  Definition of the custom external managed node role to be added to
  the roles_data.yaml shipped in THT. 

- externally-managed.yaml
  Parameter overrides environment file mostly defining network ports
  to get network isolation on the custom role. 

- deploy-externally-managed-node.sh
  Example deployment command. Note that network.yaml is from: 
  https://github.com/RHsyseng/hci/blob/master/custom-templates/network.yaml
