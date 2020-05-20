#!/bin/bash

kubectl -n kubernetes-dashboard -o json get secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}') | jq -rM ".data.token" | base64 -d | pbcopy
echo "Copied to clipboard"
