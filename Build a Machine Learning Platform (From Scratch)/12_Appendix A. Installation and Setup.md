# Appendix A. Installation and Setup

Kubernetes is the platform on which we have deployed multiple MLOps tools and projects, so the first step would be to set it up. Usually Kubernetes (or K8s) is associated with a cluster of nodes and deployments spread across multiple node pools (collection of nodes), we will be presenting two ways of installing it: Local vs Cloud. Both work well and have their pros and cons, depending on your use case you can go with either. We suggest that if you are new to K8s, try out a local installation which is a good way to start and then you can proceed to using K8s on cloud to run and deploy your projects.

## A.1 Local Installation Of Command Line Tools (Mac And Linux)

We need to install some command line tools before we proceed to install Kubernetes and Kubeflow.

#### Yq

Yq is a yaml processor which allows one to edit a yaml file from command line, quite useful while writing CI pipelines and installations. Run the following script to install it:

```
123export VERSION=v4.2.0  
export BINARY=yq_linux_amd64  
wget "https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY}" -O /usr/bin/yq && chmod +x /usr/bin/yq
```

Or on mac:

```
brew install yq
```

#### Kustomize

Kustomize is a config management utility in K8s, it helps in modifying and combining our yaml artifacts which are necessary for this installation. Run the following to install Kustomize:

```
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
```

Then move the downloaded kustomize binary to $PATH (e.g. /usr/local/bin):

```
mv kustomize /usr/local/bin
```

Or on Mac:

```
brew install kustomize
```

#### Kubectl

Kubectl is the command line tool which you will be using extensively to interact with your K8s cluster and resources. To install it run the following

```
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```

Then move the downloaded kubectl binary to $PATH (e.g. /usr/local/bin):

```bash
12chmod +x kubectl
mv kubectl /usr/local/bin
```

#### K8s Distribution

After installing the above utilities we have to choose which K8s distribution to go with. There are multiple distributions available as our goal is to get up and running quickly and minifying the setup times we suggest using k3 or microK8s. K3s is suitable for linux based installation where microk8s is recommended for mac based installation.

A local installation of K8s consumes a significant amount of resources. To start with ensure you have at least 4 CPU, 12GB memory and at least 50GB of disk space free, 100 GB would be ideal. Need to install a few tools which will aid us in installing K8s.

#### K3s Installation

K3s is a great option because it is a lightweight version of Kubernetes and is simpler to manage with lesser moving parts. It also provides scripts to easily stop the K3s services and install K3s if needed.

It is one of the easier ways to install Kubernetes and Kubeflow 1.7 with the least trouble, and this is the approach we recommend because it’s the best balance between getting the latest Kubeflow and Kubernetes (at the time of writing this book) and ease of install. Run this script to install k3s

```
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.26.3+k3s1" INSTALL_K3S_EXEC="server --no-deploy=traefik" K3S_KUBECONFIG_MODE="644" sh -s
```

Then:

```
123mkdir ~/.kube  
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config  
export KUBECONFIG="~/.kube/config"
```

Add the following line to your ~/.bashrc (or whatever shell you’re using):

```
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
```

Followed by:

```
source ~/.bashrc
```

Check everything got installed properly:

```bash
kubectl get no
```

You should see something like:

```
12NAME STATUS ROLES AGE VERSION  
artemis Ready control-plane,master 3m36s v1.20.6+k3s1
```

If you get Config not found: ~/.kube/config

then ensure the permission for ~/.kube/config is set to 644, also try giving the absolute path of the config file.

#### microK8s Installation

microK8s is another lightweight k8s distribution which takes less time to set up and works well with both Mac and linux.

To set up microK8s for mac we will be using Multipass to spawn a Ubuntu VM in Mac.

First we install microK8s

```
brew install ubuntu/microk8s/microk8s
```

We then specify the vm specifications by running:

```
microk8s install --cpu 4 --mem 12 --disk 50 --channel 1.26
```

Wait for microk8s to start:

```
microk8s status --wait-ready
```

We need to enable dns for microK8s:

```
microK8s enable dns
```

To make microk8s work with our installed kubectl we have to run the following:

```
cd $HOME
mkdir .kube
cd .kube
microk8s config > config
```

Then copy over this line to bashrc, zshrc or any other shell use are using:

```
export KUBECONFIG="$HOME/.kube/config"
```

Once microK8s has started you can try:

```bash
kubectl get po
```

You should be able to see a list of pods or a message which says:

```
No resources found in default namespace.
```

If you get Config not found: ~/.kube/config

then ensure the permission for ~/.kube/config is set to 644.

### A.1.1 Argo CD

Argo CD is a Git Ops Continuous Delivery tool which runs on Kubernetes. It can help us to deploy the Kubeflow manifests (collection of yaml files). All we have to do is to maintain these manifests in a git repository. To update the Kubeflow deployment we just have to push our manifest changes to this git repo and Argo CD takes care of deploying it. To install Argo CD we do the following

Git clone the argo cd repo

```
git clone https://github.com/vmallya-123/kubeflow-argo
cd kubeflow-argo
```

Deploy argocd using kubectl:

```bash
kubectl apply -k argocd/
```

Wait for a minute for ArgoCD to deploy. Run the following command to watch (-w) for all the pods in the argocd namespace to spin up:

```bash
kubectl get po -n argocd -w
```

You can hit Ctrl + C to exit once all the pods under STATUS are marked as Running:

```bash
kubectl get po -n argocd -w  
NAME READY STATUS RESTARTS AGE  
argocd-redis-759b6bc7f4-cbpjw 1/1 Running 0 2m  
argocd-dex-server-66ff89cb7b-fcjrd 1/1 Running 0 2m  
argocd-application-controller-0 1/1 Running 0 2m  
argocd-repo-server-5ddd7d95b6-tch9h 1/1 Running 0 2m  
argocd-server-7fd556c67c-qzv5l 1/1 Running 0 2m
```

To access the argo CD UI we need to first retrieve the admin password, to do so run the following:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Note the password, which is the output of the above command.

Port-forward the ArgoCD service:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Then open `http://localhost:8080`. You might need to accept the security exception on your browser.

Once you reach the login screen you will need to enter the username, the default username is admin and the password is the text which you retrieved from the above step.

Once you login you will be able to see the Argo CD dashboard:

![](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/A__image001.png)

### A.1.2 Kubeflow

In the kubeflow-argocd repo run:

```bash
kubectl apply -f kubeflow.yaml
```

You should notice that a bunch of applications are being deployed using ArgoCD. You will see new boxes spawning on the ArgoCD UI. Everything will take a while to get started (mine took around 30 minutes). Don’t be alarmed if you were to see some boxes turning red at first. Patience is key here!

Once all application turn green you can proceed to access the Kubeflow UI, for this we need to retrieve the Istio service IP by running:

```bash
kubectl get svc istio-ingressgateway -n istio-system
```

which returns:

```
NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE  
istio-ingressgateway LoadBalancer 10.43.178.189 10.242.8.10 15021:30650/TCP,80:32506/TCP,443:32601/TCP,31400:30067/TCP,15443:31616/TCP 110m
```

If EXTERNAL-IP is present you can access it via that (`https://10.242.8.10`) or you can also access it via CLUSTER-IP (`https://10.43.178.189`).

Once you access Kubeflow UI, you will be greeted with the login screen where you can enter the default credentials. Username is `user@kubeflow.org` and password is 12341234.

Kubeflow awaits you

![](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/A__image003.png)

### A.1.3 Cloud Provider K8s Setup

A simple Kubeflow installation works well in most workstations and laptops. However you may find that as you add on more workload in the form of pipelines or batch jobs, your single node laptop may not meet the resource requirements. In this scenario we recommend you switch over to using a managed Kubernetes service provided by any major cloud provider. Most of these cloud providers also provide free credits which if used properly can take you through the code samples/exercises specified in the book. Two major cloud providers are GCP and AWS.

To set up GKE (Google Kubernetes Engine), we need to first register for GCP. If this is your first time using GCP you will be able to claim about $300 free credits which you can use within 90 days as specified here: [https://cloud.google.com/free/docs/free-cloud-features#free-trial](https://cloud.google.com/free/docs/free-cloud-features#free-trial).

Once you sign up you will be able to setup a cluster by following the setup instructions specified here: [https://cloud.google.com/kubernetes-engine/docs/how-to/creating-an-autopilot-cluster](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-an-autopilot-cluster)

If you prefer to use AWS there is the EKS (Elastic Kubernetes Service) which can be setup by following the steps specified in [https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html](https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html).

Another cloud provider which provides free credits and is simple to use is Digital Ocean. You can sign up here [https://try.digitalocean.com/kubernetes-in-minutes/](https://try.digitalocean.com/kubernetes-in-minutes/). After signing up you can set up a K8s cluster by following [https://docs.digitalocean.com/products/kubernetes/getting-started/](https://docs.digitalocean.com/products/kubernetes/getting-started/)

It is very important that you monitor the cloud costs. Each of the cloud providers provide you with setting up billing alerts, which you can use to alert the moment you are charged above a certain threshold.

### A.1.4 MLflow Setup

The MLFlow service which is used as a tracker and model registry needs a backend store such as Postgres to store metrics, parameters and MLFlow metadata. It also needs an artifact/object store for storing artifacts such as files.

We will use a MinIO artifact store and a Postgresql service deployed in K8s cluster for our backend store. We will use the MinIO deployed by setting up Kubeflow and set up our Postgres server by following the below instructions.

#### Setup Postgres

We need to ensure we have Helm installed. Helm is a package manager for Kubernetes that simplifies the deployment and management of applications on Kubernetes clusters by defining, installing, and upgrading even complex Kubernetes applications. Install Helm on the local machine by following the instructions on the official Helm website: [https://helm.sh/docs/intro/install/](https://helm.sh/docs/intro/install/). To learn more about Helm see section 3.2.6.

Once Helm is setup we need to add the Helm chart repo and update it

```
12helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

Once done we can proceed to install Postgres in Postgres namespace by running the below commands

First create the namespace if it does not exist

```bash
kubectl create namespace postgres
```

Install Postgres in the Postgres namespace

```
helm install postgres-release bitnami/postgresql --namespace postgres
```

Which would give us the below output. This give us information on how to retrieve the password along with how we can port forward to the Postgres server.

```bash
NAME: postgres-release
LAST DEPLOYED: Sat Jan 13 12:47:00 2024
NAMESPACE: postgres
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: postgresql
CHART VERSION: 13.2.29
APP VERSION: 16.1.0
** Please be patient while the chart is being deployed **
PostgreSQL can be accessed via port 5432 on the following DNS names from within your cluster:
    postgres-release-postgresql.postgres.svc.cluster.local - Read/Write connection
To get the password for "postgres" run:
    export POSTGRES_PASSWORD=$(kubectl get secret --namespace postgres postgres-release-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)
To connect to your database run the following command:
    kubectl run postgres-release-postgresql-client --rm --tty -i --restart='Never' --namespace postgres --image docker.io/bitnami/postgresql:16.1.0-debian-11-r19 --env="PGPASSWORD=$POSTGRES_PASSWORD" \
      --command -- psql --host postgres-release-postgresql -U postgres -d postgres -p 5432
    > NOTE: If you access the container using bash, make sure that you execute "/opt/bitnami/scripts/postgresql/entrypoint.sh /bin/bash" in order to avoid the error "psql: local user with ID 1001} does not exist"
To connect to your database from outside the cluster execute the following commands:
    kubectl port-forward --namespace postgres svc/postgres-release-postgresql 5432:5432 &
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432
```

We can verify its installation by checking the pods in Postgres namespace

```bash
kubectl get pod -n postgres
```

Keep note of the Postgres password by running

```bash
export POSTGRES_PASSWORD=$(kubectl get secret --namespace postgres postgres-release-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)
```

#### Build MLflow Docker image

We then proceed to build MLflow Docker image by defining the Dockerfile.

##### Listing A.1 MLFlow Dockerfile

```dockerfile
FROM python:3.11-slim-buster
RUN pip3 install --upgrade pip && \
    pip3 install mlflow==2.6.0 boto3 minio psycopg2-binary
```

We then build the Docker image and push it to your personal Dockerhub. This is done by running

```bash
docker build . -t varunmallya/mlflow:v1
docker push varunmallya/mlflow:v1
```

#### Deploy MLflow

To deploy MLflow we need to define Kubernetes manifests. This includes the deployment.yaml and service yaml.

##### Listing A.2 MLflow Deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
 name: mlflow-deployment
 namespace: mlflow
 labels:
   app: mlflow
spec:
 replicas: 1
 selector:
   matchLabels:
     app: mlflow
 template:
   metadata:
     labels:
       app: mlflow
   spec:
     containers:
       - name: mlflow
         image: varunmallya/mlflow:latest
         imagePullPolicy: Always
         env:
          - name: AWS_ACCESS_KEY_ID
            value: minio
          - name: AWS_SECRET_ACCESS_KEY
            value: minio123
          - name: AWS_ENDPOINT_URL
            value: http://minio-service.kubeflow.svc.cluster.local:9000
 
         command: ["/bin/bash"]
         args:
           [
             "-c",
             "mlflow server --host 0.0.0.0 --default-artifact-root s3://mlflow-artifacts --backend-store-uri postgresql+psycopg2://postgres:qrH8fT7aNP@postgres-release-postgresql.postgres.svc.cluster.local:5432/postgres",
           ]
         ports:
           - containerPort: 5000
```

##### Listing A.3 MLflow Service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mlflow-service
  namespace: mlflow
spec:
  selector:
    app: mlflow
  ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000
```

Once we create these resources using Kubectl create we can access MLflow in our local by running the port forwarding command

```
k port-forward svc/mlflow-service -n mlflow 5000:5000
```

### A.1.5 Redis Online Store Setup

We will install Redis by using a Helm chart by running these commands. This Redis can be used as an online store by Feast.

```bash
123helm repo add bitnami https://charts.bitnami.com/bitnami
Kubectl create namespace redis
helm install my-redis bitnami/redis --namespace redis
```

We can confirm Redis deployment by running

```bash
kubectl get deployment -n redis
```

Once confirmed can use this redis for Feast

### A.1.6 BentoML Setup

We will be setting up Yatai in BentoML. Yatai is the component in the BentoML framework that lets us deploy, operate, and scale Machine Learning services on Kubernetes. We will install this by using Helm.

```bash
helm repo add bentoml https://bentoml.github.io/helm-charts
helm repo update bentoml
kubectl create ns yatai-system
helm install yatai-test bentoml/yatai --set ingress.enabled=false --set service.type=LoadBalancer -n yatai-system --create-namespace
```

This will set up the Yatai and we need to create an admin account by running the initialization statements displayed when we run the helm install command

```bash
1234When installing Yatai for the first time, run the following command to get an initialization link for creating your admin account:
export YATAI_INITIALIZATION_TOKEN=$(kubectl get secret yatai-env --namespace yatai-system -o jsonpath="{.data.YATAI_INITIALIZATION_TOKEN}" | base64 --decode)
export SERVICE_IP=$(kubectl get svc --namespace yatai-system yatai --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
echo "Create admin account at: http://$SERVICE_IP:80/setup?token=$YATAI_INITIALIZATION_TOKEN"
```

Using the above URL login from your browser, which will take you to Yatai initial account set up screen. You will then have to enter the username, password and email and create the admin account.

![](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/A__image005.png)

After creating and account and logging in we can you Yatai for Bento deployment and storage.

### A.1.7 Evidently UI Setup

To setup Eviedently UI for data drift in monitoring in K8s we need to set up a Docker image with Evidently dependencies installed

##### Listing A.4 Evidently UI Dockerfile

```dockerfile
FROM python:3.9-slim-buster
WORKDIR /app
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    build-essential \
    && apt-get clean && rm -rf /tmp/* /var/tmp/*
 
COPY requirements.txt /app/requirements.txt
RUN pip3 install --upgrade pip
RUN pip3 install --no-cache-dir -r requirements.txt
ENV PYTHONPATH "/app"
COPY . /app
EXPOSE 8000
ENTRYPOINT ["evidently","ui"]
```

We build the Docker image and push it to Docker hub by running

```bash
docker build . -t varunmallya/evidently-ui:latest
docker push varunmallya/evidently-ui:latest
```

We then setup the namespace, deployment and service in Kubernetes using Kubectl.

##### Listing A.5 Evidently UI Namespace.yaml

```yaml
apiVersion: v1
kind: Namespace
metadata:
  creationTimestamp: null
  name: evidently
```

##### Listing A.6 Evidently UI Deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: evidently-ui
  name: evidently-ui
  namespace: evidently
spec:
  replicas: 1
  selector:
    matchLabels:
      app: evidently-ui
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: evidently-ui
    spec:
      containers:
      - image: varunmallya/evidently-ui:latest
        name: evidently-ui
        ports:
        - containerPort: 8000
```

##### Listing A.7 Evidently UI Service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: evidently-ui
  name: evidently-ui
  namespace: evidently
spec:
  ports:
  - name: 8000-8000
    port: 8000
    protocol: TCP
    targetPort: 8000
  selector:
    app: evidently-ui
  type: ClusterIP
```

Once we setup the namespace and deployment we can use the UI for visualizing drift reports. We do that by running Kubectl apply.
