#!/bin/sh

# elastico version
curl -O https://raw.githubusercontent.com/elastic/Helm-charts/master/elasticsearch/examples/minikube/values.yaml
helm repo add elastic https://helm.elastic.co
helm install --name elasticsearch elastic/elasticsearch -f ./values-elasticsearch.yml
helm install --name kibana elastic/kibana -f ./values-kibana.yaml