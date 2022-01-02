#!/bin/bash

cd ./cassandra_cluster_setup;
terraform apply -auto-approve;
./cassandra_nodes_configuration.sh;

