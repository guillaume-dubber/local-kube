#!/bin/sh

kubectl create namespace idp
helm repo add codecentric https://codecentric.github.io/helm-charts
helm install --name keycloak codecentric/keycloak --namespace idp -f values-keycloak.yaml

echo "Username: \nkeycloak\n"
echo "Password: "
kubectl get secret --namespace idp keycloak-http -o jsonpath="{.data.password}" | base64 --decode; echo