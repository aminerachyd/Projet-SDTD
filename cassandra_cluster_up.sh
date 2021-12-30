#!/bin/bash

cd ./cassandra_cluster_setup;
terraform apply -var-file=variables.tfvars -auto-approve;
./cassandra_nodes_configuration.sh;

