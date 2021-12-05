# Commandes pour setup un cluster avec Kops

Il faudra d'abord installer kops et ajouter l'option d'utiliser GCE qui est en version alpha (voir l'installation sur la page kOps), il faudra également avoir kubectl installé sur sa machine

Après l'installation de kOps, on lance les commandes suivantes :

```
# Creation de bucket sur GCP pour enregistrer l'état du cluster
export KOPS_STATE_STORE=gs://my-kops-state/

gsutil mb -l europe-west1 $KOPS_STATE_STORE

# Lancement de la commande kops avec le projet GCP qu'on souhaite utiliser

PROJECT=`gcloud config get-value project`

kops create cluster simple.k8s.cluster --zones europe-west1-a --state $KOPS_STATE_STORE --project=$PROJECT

kops update cluster --name simple.k8s.cluster --yes --admin
```

Le cluster prend du temps à démarrer, on lance la commande suivante qui vérifie son état pendant 10min

```
kops validate cluster --wait 10m
```

On pourrait après output la configuration dans un fichier terraform.  

Creation d'un cluster avec plusieurs masters, le nombre des masters est égal au nombre de zones (chaque master dans une zone), le nombre des workers peut varier  
Le nombre maximum de workers que j'ai pu mettre est de 5, ça fait une distribution de 2 2 1 sur les 3 régions  
```
kops create cluster --node-count 5 --zones europe-west1-b,europe-west1-c,europe-west1-d --master-zones europe-west1-b,europe-west1-c,europe-west1-d simple.k8s.local
```
