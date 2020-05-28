#!/bin/sh

kubectl create namespace storage
helm repo add bitnami https://charts.bitnami.com/bitnami

helm install --name postgres bitnami/postgresql