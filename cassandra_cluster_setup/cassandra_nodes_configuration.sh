#!/bin/sh

NODE1_PUB=$(terraform output -json | jq -r .node1_public_ip.value);
NODE1_PVT=$(terraform output -json | jq -r .node1_self_ip.value);
NODE2_PUB=$(terraform output -json | jq -r .node2_public_ip.value);
NODE2_PVT=$(terraform output -json | jq -r .node2_self_ip.value);

echo \{\"self_public\":$NODE1_PUB,\"self_private\":$NODE1_PVT,\"other_public\":$NODE2_PUB\} > NODE1_JSON.json;
echo \{\"self_public\":$NODE2_PUB,\"self_private\":$NODE2_PVT,\"other_public\":$NODE1_PUB\} > NODE2_JSON.json;

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook playbooks/cassandra_nodes_setup.yml -u amine -i $(echo "$NODE1_PUB,") --private-key ~/.ssh/id_rsa -e "@NODE1_JSON.json"

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook playbooks/cassandra_nodes_setup.yml -u amine -i $(echo "$NODE2_PUB,") --private-key ~/.ssh/id_rsa -e "@NODE2_JSON.json"
