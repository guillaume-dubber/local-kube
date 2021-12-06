export HOSTFILE ?= '/etc/hosts'
export HOSTLINE ?= "127.0.0.1 local.dubber.io portal-local s3.portal-local dashboard.portal-local kibana-portal-local jmeter.portal-local jmeterreport.portal-local portallive.portal-local portalreport.portal-local jenkins.portal-local"										
export LOCALDOMAIN ?= portal-local
export TLS_SECRET ?= portal-tls-secret
export TARGET_NS ?= ingress-nginx

export DOCKER_USER=dubberdockerhub
export DOCKER_REGISTRY_SERVER ?= 'https://index.docker.io/v1/'
export DOCKER_EMAIL ?= dockerhub@dubber.net
export DOCKER_PASSWORD ?=

all: help

help: 
	@echo "deploy-tiller              - creates tiller server in the cluster"	
	@echo "deploy-ingress             - creates an ingress controller"
	@echo "setup-hostfile             - adds entries in /etc/hosts pointing at the local cluster"
	@echo "deploy-users               - creates an admin user"
	@echo "deploy-dashboard           - installs the k8s dashboard"
	@echo "deploy-minio               - Sets up S3-like storage service (minio/minio123)"
	@echo "deploy-backup              - Sets up backup service for k8s"
	@echo "install-minica             - "
	@echo "gen-cert                   - "
	@echo "install-jenkins            - "
	@echo "clean-users                - "
	@echo "clean-dashboard            - "
	@echo "clean-ingress              - "
	@echo "clean-minio                - "
	@echo "install-kind               - "
	@echo "create-kind-cluster        - "
	@echo "delete-kind-cluster        - "

deploy-tiller:
	helm init

deploy-ingress:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-0.32.0/deploy/static/provider/cloud/deploy.yaml

setup-hostfile:
	grep -qF -- ${HOSTLINE} ${HOSTFILE} || echo ${HOSTLINE} | sudo tee -a ${HOSTFILE}

deploy-users:
	kubectl apply -f users/admin-user.yaml

deploy-dashboard:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.1/aio/deploy/recommended.yaml
	helm install bitnami/metrics-server -f dashboard/metrics-server-values.yaml --name metrics-server --namespace kube-system
	kubectl apply -f dashboard/dashboard-ingress.yaml -n kubernetes-dashboard

deploy-minio:
	kubectl apply -f backup/velero-v1.3.2-darwin-amd64/examples/minio/00-minio-deployment.yaml
	kubectl apply -f backup/minio-ingress.yaml -n velero

deploy-backup:
	velero install \
    --provider aws \
    --bucket velero \
    --secret-file ./backup/credentials-velero \
    --use-volume-snapshots=false \
    --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://minio.velero.svc:9000

install-minica:
	git clone https://github.com/jsha/minica.git \
	&& cd minica && go build \
	&& mv minica /usr/local/bin \
	&& cd .. && rm -rf minica/

gen-cert: 
	@echo "Creating cert for local ingress and adding secret to cluster"
	@cd certs \
	&& minica --ca-cert ca.pem --ca-key ca-key.pem --domains ${LOCALDOMAIN} 2> /dev/null || true \
	&& kubectl create secret tls ${TLS_SECRET} \
    --namespace ${TARGET_NS} \
    --key portal-local/key.pem \
    --cert portal-local/cert.pem 2>/dev/null || true

install-jenkins:
	@echo "Installing latest Jenkins"
	@kubectl create namespace jenkins 2>/dev/null || true
	@helm upgrade --install jenkins stable/jenkins --namespace jenkins
	@kubectl apply -f jenkins/jenkins-ingress.yaml --namespace jenkins
	@echo "Admin password is: "
	kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode

create-docker-secret:
	kubectl create secret docker-registry myregistrykey \
  --dry-run=client -o yaml \
  --docker-server=${DOCKER_REGISTRY_SERVER} \
  --docker-username=${DOCKER_USER} \
  --docker-password=${DOCKER_PASSWORD} \
  --docker-email=${DOCKER_EMAIL} \
  > dubberdockerhub_secret.yaml

clean-users:
	kubectl delete -f users/admin-user.yaml

clean-dashboard:
	kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.1/aio/deploy/recommended.yaml
	kubectl delete -f dashboard/dashboard-ingress.yaml -n kubernetes-dashboard

clean-ingress:
	kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-0.32.0/deploy/static/provider/cloud/deploy.yaml

clean-minio:
	kubectl delete -f backup/velero-v1.3.2-darwin-amd64/examples/minio/00-minio-deployment.yaml
	kubectl delete -f backup/minio-ingress.yaml -n velero

install-kind:
	GO111MODULE="on" go get sigs.k8s.io/kind@v0.11.1

create-kind-cluster:
	time bash ./kind/setup-with-registry.sh
	@echo "created a cluster in the context kind-kind and a docker registry on localhost:5000"
	@echo "accessible both on your local machine and in k8s"

delete-kind-cluster:
	time kind delete cluster

install-kind-ingress:
	VERSION=$(curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/stable.txt) \
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/${VERSION}/deploy/static/provider/kind/deploy.yaml
	kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=90s