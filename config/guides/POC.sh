# [GKE]
# Creating the cluster
gcloud beta container --project "istiotest-239415" clusters create "gke-local-cluster" --zone "europe-west1-b" --no-enable-basic-auth --cluster-version "1.12.8-gke.10" --machine-type "n1-standard-2" --image-type "COS" --disk-type "pd-standard" --disk-size "100" --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "2" --enable-cloud-logging --enable-cloud-monitoring --enable-ip-alias --network "projects/istiotest-239415/global/networks/gke-poc-vpc" --subnetwork "projects/istiotest-239415/regions/europe-west1/subnetworks/gke-poc-subnet" --cluster-ipv4-cidr "10.1.0.0/20" --services-ipv4-cidr "172.16.0.0/24" --default-max-pods-per-node "110" --addons HorizontalPodAutoscaling,HttpLoadBalancing --enable-autoupgrade --enable-autorepair

# Cloning into my Git
git clone https://github.com/MarioGabriel/istio.git

# Downloading Latest Istio
curl -L https://git.io/getLatestIstio | sh -

# Downloading Helm
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash

cd istio
export PATH="$PATH:$(pwd)/istio-1.2.2/bin" # for istioctl
export PATH="$PATH:$(pwd)/config" # for ctx
cd istio-1.2.2

ctx gke

NAMESPACE=istio-system
kubectl create namespace $NAMESPACE

# Kubernetes Dashboard
kubectl create serviceaccount k8sadmin -n kube-system
kubectl create clusterrolebinding k8sadmin --clusterrole=cluster-admin --serviceaccount=kube-system:k8sadmin
kubectl get secret $(kubectl get secret -n kube-system | grep k8sadmin-token | cut -d " " -f1) -n kube-system -o 'jsonpath={.data.token}' | base64 --decode
# Token : 
#  eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJrOHNhZG1pbi10b2tlbi16NmY0cSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJrOHNhZG1pbiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6Ijc2MGY0MmRiLWFhMDItMTFlOS1iNDYxLTQyMDEwYTg0MDBkNSIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlLXN5c3RlbTprOHNhZG1pbiJ9.VFOx271cQYxCSmdEL3qC-GryX-ssPTpmor8QiGw1LurWzFKEJ226bsaewVifndINPVafS5uXl56xeC9o3kLzDS_m0pKH1P7PAxZgwhfqoh1Umf4eCEVfE6iNRbYUSDfft23XWZQH4O1hO29KqYfHVtsvV7E9SaDapZ8iIPwhYLc8Uwcnne66ZfAc4DTpogELSq4yWyYI5HjDxqtEFoQPNC8W8_wCVZGXV8gDZOkdcZF1h1KPd1xR4ZFpE34KnnM1oT7sR6l3_zYfWVkKOARH_SbwpVFniAu14141_nk8hEqoItarFOkyqxts3trh__WFBQ2nig5kXB84lNgX24fMJw

# Deploy the dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta1/aio/deploy/recommended.yaml

# $ kubectl proxy # to deploy the dashboard and paste the token above to access it

# Username and pass for kiali dashboard
KIALI_USERNAME=$(read -p 'Kiali Username: ' uval && echo -n $uval | base64)
KIALI_PASSPHRASE=$(read -sp 'Kiali Passphrase: ' pval && echo -n $pval | base64)

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

# Installing helm
kubectl apply -f install/kubernetes/helm/helm-service-account.yaml
helm init --service-account tiller
helm repo update

# Checking if the cluster is OK for Istio install
istioctl verify-install

# Installing Istio CRDs
helm install --name=istio-init install/kubernetes/helm/istio-init --namespace istio-system

kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l # must return 23 after Istio 1.2

# Installing full Istio Control Plane
helm install install/kubernetes/helm/istio --name istio --namespace istio-system --set tracing.enabled=true --set ingress.enabled=true --set gateways.enabled=true --set gateways.istio-ingressgateway.enabled=true --set gateways.istio-egressgateway.enabled=true --set sidecarInjectorWebhook.enabled=true --set galley.enabled=true --set mixer.enabled=true --set mixer.istio-policy.autoscaleEnabled=true --set mixer.istio-telemetry.autoscaleEnabled=true --set pilot.enabled=true --set telemetry-gateway.grafanaEnabled=true --set telemetry-gateway.prometheusEnabled=true --set grafana.enabled=true --set prometheus.enabled=true --set servicegraph.enabled=true --set tracing.ingress.enabled=true --set kiali.enabled=true

# Getting Istio Pod IPs for Remote Cluster
export PILOT_POD_IP=$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath='{.items[0].status.podIP}')
export POLICY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=policy -o jsonpath='{.items[0].status.podIP}')
export TELEMETRY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=telemetry -o jsonpath='{.items[0].status.podIP}')
export ZIPKIN_POD_IP=$(kubectl -n istio-system get pod -l app=jaeger -o jsonpath='{range .items[*]}{.status.podIP}{end}')

# [EKS]
# Creating the cluster
# eksctl create cluster --name=test-cluster --zone="us-east1a"

ctx eks

# Installing Helm
kubectl apply -f install/kubernetes/helm/helm-service-account.yaml
helm init --service-account tiller
helm repo update

# Installing istio-remote
helm install install/kubernetes/helm/istio \
--name istio-remote --namespace istio-system \
--values install/kubernetes/helm/istio/values-istio-remote.yaml \
--set global.remotePilotAddress=${PILOT_POD_IP} \
--set global.remotePolicyAddress=${POLICY_POD_IP} \
--set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} \
--set global.remoteZipkinAddress=${ZIPKIN_POD_IP}

# Getting remote cluster credentials ...
cd ../config

export WORK_DIR=$(pwd)
CLUSTER_NAME=$(kubectl config view --minify=true -o jsonpath='{.clusters[].name}')
export KUBECFG_FILE=${WORK_DIR}/${CLUSTER_NAME}
SERVER=$(kubectl config view --minify=true -o jsonpath='{.clusters[].cluster.server}')
NAMESPACE=istio-system
SERVICE_ACCOUNT=istio-multi
SECRET_NAME=$(kubectl get sa ${SERVICE_ACCOUNT} -n ${NAMESPACE} -o jsonpath='{.secrets[].name}')
CA_DATA=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o jsonpath="{.data['ca\.crt']}")
TOKEN=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o jsonpath="{.data['token']}" | base64 --decode)

# ...and putting them into a file
cat <<EOF > ${KUBECFG_FILE}
apiVersion: v1
clusters:
   - cluster:
       certificate-authority-data: ${CA_DATA}
       server: ${SERVER}
     name: ${CLUSTER_NAME}
contexts:
   - context:
       cluster: ${CLUSTER_NAME}
       user: ${CLUSTER_NAME}
     name: ${CLUSTER_NAME}
current-context: ${CLUSTER_NAME}
kind: Config
preferences: {}
users:
   - name: ${CLUSTER_NAME}
     user:
       token: ${TOKEN}
EOF

cat <<EOF > remote_cluster_env_vars
export CLUSTER_NAME=${CLUSTER_NAME}
export KUBECFG_FILE=${KUBECFG_FILE}
export NAMESPACE=${NAMESPACE}
EOF

# [GKE]

ctx gke

source remote_cluster_env_vars

# Passing onto Istio (and Kubernetes) the information about the remote cluster
kubectl create secret generic ${CLUSTER_NAME} --from-file ${CLUSTER_NAME} -n ${NAMESPACE}
kubectl label secret ${CLUSTER_NAME} istio/multiCluster=true -n ${NAMESPACE}