kubectl delete all --all;

./cassandra_cluster_down.sh && ./k8s_cluster_down.sh;

echo "### L'infra est down ###";
