#!/bin/bash

eksctl utils write-kubeconfig --name=test-cluster -v 0
gcloud container clusters get-credentials gke-local-cluster --zone europe-west1-b --project istiotest-239415 --no-user-output-enabled

eks=$(kubectl config get-contexts -o='name' | grep 'eks')
gke=$(kubectl config get-contexts -o='name' | grep 'gke')


set_gke () {
	kubectl config use-context $gke
}

set_eks () {
	kubectl config use-context $eks
}


if [$1 = gke]
then
	set_gke
elif [$1 = eks]
then 
	set_eks
else
	echo "No valid context given"
fi