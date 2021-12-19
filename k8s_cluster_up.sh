#!/bin/bash

kops create cluster --node-count 3 --zones europe-west1-b --master-zones europe-west1-b simple.k8s.local && kops update cluster --name simple.k8s.local --yes --admin && kops validate cluster --wait 10m
