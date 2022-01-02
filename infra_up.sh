#!/bin/bash

export TF_VAR_pvt_key="~/.ssh/id_rsa";
export TF_VAR_pub_key="~/.ssh/id_rsa.pub";
export TF_VAR_ssh_username=$(whoami);
export TF_VAR_project=$(gcloud config get-value project);
export TF_VAR_project_region="europe-west1";
export TF_VAR_project_zone="europe-west1-b";
export TF_VAR_cassandra_setup_playbook="playbooks/cassandra_setup_playbook.yml";

./cassandra_cluster_up.sh && ./k8s_cluster_up.sh;

echo "### L'infra est UP, n'oubliez pas de lancer le script down pour tout éteindre ###";
