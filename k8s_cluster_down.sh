#!/bin/bash
export KOPS_STATE_STORE="gs://my-kops-state/";

kops delete cluster simple.k8s.local --yes
