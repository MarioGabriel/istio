# Deploying the clusters #

## Deploying the local GKE cluster

gcloud beta container --project "istiotest-239415" clusters create "gke-local-cluster" --zone "europe-west1-b" --no-enable-basic-auth --cluster-version "1.12.8-gke.10" --machine-type "n1-standard-2" --image-type "COS" --disk-type "pd-standard" --disk-size "100" --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "2" --enable-cloud-logging --enable-cloud-monitoring --enable-ip-alias --network "projects/istiotest-239415/global/networks/gke-poc-vpc" --subnetwork "projects/istiotest-239415/regions/europe-west1/subnetworks/gke-poc-subnet" --cluster-ipv4-cidr "10.1.0.0/20" --services-ipv4-cidr "172.16.0.0/24" --default-max-pods-per-node "110" --addons HorizontalPodAutoscaling,HttpLoadBalancing --enable-autoupgrade --enable-autorepair


## Deploying the Remote EKS Cluster

`eksctl create cluster --config-file=eks-config.yaml`

`cat eks-config.yaml`

> apiVersion: eksctl.io/v1alpha5
> kind: ClusterConfig
>
> metadata:
>   name: eks-remote-cluster
>   region: us-east-2
>   version: "1.12"
>
> vpc:
>   id: "vpc-0d8f2a13f73f0db9e"
>   cidr: "10.100.0.0/16"
>   subnets:
>     public:
>       us-east-2a: {id: subnet-0007b522f2d51de46, cidr: 10.100.1.0/24}
>       us-east-2b: {id: subnet-08a2b29c345c0b56f, cidr: 10.100.2.0/24}
>       us-east-2c: {id: subnet-0d468f4045aae0592, cidr: 10.100.3.0/24}
>
> iam:
>   serviceRoleARN: "arn:aws:iam::448647583624:role/eks-iam-role"
> nodeGroups:
>
> - name: standard-workers
>   	instanceType: t2.medium
>   	desiredCapacity: 2
>   	ami: auto
>   	minSize: 1
>   	maxSize: 4
>   	availabilityZones: ["us-east-2a","us-east-2b","us-east-2c"]
>   	iam:
>   	  withAddonPolicies:
>   	    imageBuilder: true
>   	    autoScaler: true
>   	ssh:
>   	  allow: true

# Configuring the Clusters

## In your local GKE cluster :  ## 

`git clone https://github.com/MarioGabriel/istio.git`
`export PATH="$PATH:/home/mgigamail/istio-1.2.0/bin"`
`cd istio/istio-1.2.0`

`NAMESPACE=istio-system`
`kubectl create namespace $NAMESPACE`

`KIALI_USERNAME=$(read -p 'Kiali Username: ' uval && echo -n $uval | base64)`
`KIALI_PASSPHRASE=$(read -sp 'Kiali Passphrase: ' pval && echo -n $pval | base64)`

`cat <<EOF | kubectl apply -f -`
`apiVersion: v1`
`kind: Secret`
`metadata:`
  `name: kiali`
  `namespace: $NAMESPACE`
  `labels:`
    `app: kiali`
`type: Opaque`
`data:`
  `username: $KIALI_USERNAME`
  `passphrase: $KIALI_PASSPHRASE`
`EOF`

`helm install istio-init install/kubernetes/helm/istio-init --namespace istio-system`

`kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l`

`helm install install/kubernetes/helm/istio --name istio --namespace istio-system --set tracing.enabled=true --set ingress.enabled=true --set gateways.enabled=true --set gateways.istio-ingressgateway.enabled=true --set gateways.istio-egressgateway.enabled=true --set sidecarInjectorWebhook.enabled=true --set galley.enabled=true --set mixer.enabled=true --set mixer.istio-policy.autoscaleEnabled=true --set mixer.istio-telemetry.autoscaleEnabled=true --set pilot.enabled=true --set telemetry-gateway.grafanaEnabled=true --set telemetry-gateway.prometheusEnabled=true --set grafana.enabled=true --set prometheus.enabled=true --set servicegraph.enabled=true --set tracing.ingress.enabled=true --set kiali.enabled=true`

`export PILOT_POD_IP=$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath='{.items[0].status.podIP}')`
`export POLICY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=policy -o jsonpath='{.items[0].status.podIP}')`
`export TELEMETRY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=telemetry -o jsonpath='{.items[0].status.podIP}')`
`export ZIPKIN_POD_IP=$(kubectl -n istio-system get pod -l app=jaeger -o jsonpath='{range .items[*]}{.status.podIP}{end}')`



#### Copy these values and save in other cluster

`echo export PILOT_POD_IP=$PILOT_POD_IP; echo export POLICY_POD_IP=$POLICY_POD_IP ; echo export TELEMETRY_POD_IP=$TELEMETRY_POD_IP ; echo export ZIPKIN_POD_IP=$ZIPKIN_POD_IP`

~~~~

~~~~

# REMOTE CLUSTER

`git clone https://github.com/MarioGabriel/istio.git`
`export PATH="$PATH:/home/mgigamail/istio-1.2.0/bin"`
`cd istio/istio-1.2.0`

`helm install istio-init install/kubernetes/helm/istio-init --namespace istio-system`

`export PILOT_POD_IP=10.1.1.12`
`export POLICY_POD_IP=10.1.1.11`
`export TELEMETRY_POD_IP=10.1.0.27`
`export ZIPKIN_POD_IP=10.1.0.28`

`helm install install/kubernetes/helm/istio \`
`--name istio-remote --namespace istio-system \`
`--values install/kubernetes/helm/istio/values-istio-remote.yaml \`
`--set global.remotePilotAddress=${PILOT_POD_IP} \`
`--set global.remotePolicyAddress=${POLICY_POD_IP} \`
`--set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} \`
`--set global.remoteZipkinAddress=${ZIPKIN_POD_IP}`



`export WORK_DIR=$(pwd)`
`CLUSTER_NAME=$(kubectl config view --minify=true -o jsonpath='{.clusters[].name}')`
`export KUBECFG_FILE=${WORK_DIR}/${CLUSTER_NAME}`
`SERVER=$(kubectl config view --minify=true -o jsonpath='{.clusters[].cluster.server}')`
`NAMESPACE=istio-system`
`SERVICE_ACCOUNT=istio-multi`
`SECRET_NAME=$(kubectl get sa ${SERVICE_ACCOUNT} -n ${NAMESPACE} -o jsonpath='{.secrets[].name}')`
`CA_DATA=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o jsonpath="{.data['ca\.crt']}")`
`TOKEN=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o jsonpath="{.data['token']}" | base64 --decode)`

#### Creating a file with all these env variables
`cat <<EOF > ${KUBECFG_FILE}`
`apiVersion: v1`
`clusters:`

   - `cluster:`
       `certificate-authority-data: ${CA_DATA}`
       `server: ${SERVER}`
     `name: ${CLUSTER_NAME}`
`contexts:`
   - `context:`
       `cluster: ${CLUSTER_NAME}`
       `user: ${CLUSTER_NAME}`
     `name: ${CLUSTER_NAME}`
`current-context: ${CLUSTER_NAME}`
`kind: Config`
`preferences: {}`
`users:`
   - `name: ${CLUSTER_NAME}`
     `user:`
       `token: ${TOKEN}`
`EOF`

`cat <<EOF > remote_cluster_env_vars`
`export CLUSTER_NAME=${CLUSTER_NAME}`
`export KUBECFG_FILE=${KUBECFG_FILE}`
`export NAMESPACE=${NAMESPACE}`
`EOF`

# On local GKE Cluster
#### Find a way to copy the files remote_cluster_env_vars and ${KUBECFG_FILE} from the remote to the local cluster

`source remote_cluster_env_vars`
`kubectl create secret generic ${CLUSTER_NAME} --from-file ${KUBECFG_FILE} -n ${NAMESPACE}`
`kubectl label secret ${CLUSTER_NAME} istio/multiCluster=true -n ${NAMESPACE}`

#### Access services from different clusters
Kubernetes resolves DNS on a cluster basis. Because the DNS resolution is tied to the cluster, you must define the service object in every cluster where a client runs, regardless of the location of the service’s endpoints. To ensure this is the case, duplicate the service object to every cluster using kubectl. Duplication ensures Kubernetes can resolve the service name in any cluster. Since the service objects are defined in a namespace, you must define the namespace if it doesn’t exist, and include it in the service definitions in all clusters.

# Deploy Bookinfo
## On Local GKE
``export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')`
`export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')`
`export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')`
`export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT`
`echo $GATEWAY_URL/productpage`

> 34.77.146.243:80/productpage

#### Accessing the Kiali Dashboard

`kubectl -n istio-system port-forward kiali-7b5b867f8-ld8t6 20001:20001`

#### Creating traffic for our dashboards

`for i in {1..1000}; do curl -s -o /dev/null http://$GATEWAY_URL/productpage; done`