#!/bin/sh

kubectl config use-context portal-local

# add ingress controller to local install
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-0.32.0/deploy/static/provider/cloud/deploy.yaml

# add local domains to /etc/hosts
LINE="127.0.0.1 local.dubber.io portal-local s3.portal-local dashboard.portal-local"
FILE='/etc/hosts'
grep -qF -- "$LINE" "$FILE" || echo "$LINE" | sudo tee -a "$FILE"
