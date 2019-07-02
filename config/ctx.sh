#!/bin/bash

eksctl utils write-kubeconfig --name=test-cluster -v 0
gcloud container clusters get-credentials gke-local-cluster --zone europe-west1-b --project istiotest-239415 --no-user-output-enabled

eks=$(kubectl config get-contexts -o='name' | grep 'eks')
gke=$(kubectl config get-contexts -o='name' | grep 'gke')

if [$1 = gke]
then
	kubectl config use-context $gke
	exit 1
elif [$1 = eks]
then 
	kubectl config use-context $eks
	exit 1
else
	echo "No valid context given"
	exit 0
fi
