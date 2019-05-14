#!/bin/bash

# Make myself an admin
echo "Creating Admin Cluster Role Binding..."
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="mgigamail@gmail.com"
echo "Done."
###############################

### Deploying the Kubernetes Dashboard ###
# Apply the Kubernetes Dashboard yaml
echo "Deploying Kubernetes Dashboard..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml
echo "Done."

# Accessing the Kubernetes Dashboard
# Create the access account
echo "Creating ServiceAccount..."
kubectl create serviceaccount k8sadmin -n kube-system
kubectl create clusterrolebinding k8sadmin --clusterrole=cluster-admin --serviceaccount=kube-system:k8sadmin
echo "Done."
##########################################

### Preparing a Kiali Secret ###

# Creating a Kiali Username and Password
echo "Creating istio-system namespace and Kiali Secrets..."
NAMESPACE=istio-system
kubectl create namespace $NAMESPACE

KIALI_USERNAME=$(echo 'mario' | base64)
KIALI_PASSPHRASE=$(echo 'mario' | base64)

# Create a Kiali secret with these credentials
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: kiali
  namespace: $NAMESPACE
  labels:
    app: kiali
type: Opaque
data:
  username: $KIALI_USERNAME
  passphrase: $KIALI_PASSPHRASE
EOF

echo "Done."

################################

### Install Helm ###
# Install Helm + Tiller
echo "Installing Helm & Tiller..."
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash

# Add a Tiller service account within a kube-system
kubectl apply -f install/kubernetes/helm/helm-service-account.yaml

# Initialize helm within the tiller service account
helm init --service-account tiller

# Updates the repos for Helm repo integration
helm repo update

echo "Done."
####################

### Install Istio + Monitoring tools with Helm ###
# Download Istio
echo "Installing Istio with Helm..."
curl -L https://git.io/getLatestIstio | sh -
cd istio-1.1.5

# Install Istio CRDs
helm install install/kubernetes/helm/istio-init --name istio-init --namespace istio-system

sleep 10s

# Install Istio with Kiali, ServiceGraph, Tracing (Jaeger by default) and Grafana enabled
helm install install/kubernetes/helm/istio --name istio --namespace istio-system --set kiali.enabled=true --set servicegraph.enabled=true --set tracing.enabled=true --set grafana.enabled=true --set mixer.telemetry.resources.requests.cpu=100m --set pilot.resources.requests.cpu=200m
echo "Done."
##################################################

### Deploying an Application with Istio Service Mesh ###

# Label namespace that application object will be deployed to by the following command (take default namespace as an example)
kubectl label namespace default istio-injection=enabled

########################################################

### Deploying the Bookinfo Application ###
# Deploying the App

echo "Deploying BookInfo app and Gateway..."
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml

# Deploying the Gateway
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml

echo "Done."

# Setting Environment Variables
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT

#########################################
cat << EOF
Gateway Url       : $GATEWAY_URL
Kiali Container   : $(kubectl -n istio-system get pod -l app=kiali -o jsonpath='{.items[0].metadata.name}')
Grafana Container : $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}')
Jaeger Container  : $(kubectl -n istio-system get pod -l app=jaeger -o jsonpath='{.items[0].metadata.name}')
EOF