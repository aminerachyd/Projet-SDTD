kubectl delete all --all;

export KOPS_STATE_STORE=$(cat kops_state_store);

./cassandra_cluster_down.sh && ./k8s_cluster_down.sh;

gsutil rb $KOPS_STATE_STORE;

rm kops_state_store;

echo "### L'infra est down ###";
