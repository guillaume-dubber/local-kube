export HOSTFILE ?= '/etc/hosts'
export HOSTLINE ?= "127.0.0.1 local.dubber.io portal-local s3.portal-local dashboard.portal-local kibana-portal-local jmeter.portal-local jmeterreport.portal-local"

all: help

help: 
	@echo "deploy-tiller							- creates tiller server in the cluster"	
	@echo "deploy-ingress							- creates an ingress controller"
	@echo "deploy-users								- creates an admin user"
	@echo "setup-hostfile							- adds entries in /etc/hosts pointing at the local cluster"
	@echo "deploy-dashboard						- installs the k8s dashboard"
	@echo "deploy-minio								- Sets up S3-like storage service (minio/minio123)"
	@echo "deploy-backup							- Sets up backup service for k8s"
	@echo "clean-users"
	@echo "clean-dashboard"
	@echo "clean-ingress"
	@echo "clean-minio"

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