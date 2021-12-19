#!/bin/bash

cd ./cassandra_cluster_setup && terraform destroy -var-file=variables.tfvars -auto-approve
