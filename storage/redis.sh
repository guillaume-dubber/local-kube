#!bin/bash

kubectl create namespace storage
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install --name redis-server bitnami/redis --namespace storage

# NOTES:
# ** Please be patient while the chart is being deployed **
# Redis can be accessed via port 6379 on the following DNS names from within your cluster:

# redis-server-master.storage.svc.cluster.local for read/write operations
# redis-server-slave.storage.svc.cluster.local for read-only operations


# To get your password run:

#     export REDIS_PASSWORD=$(kubectl get secret --namespace storage redis-server -o jsonpath="{.data.redis-password}" | base64 --decode)

# To connect to your Redis server:

# 1. Run a Redis pod that you can use as a client:

#    kubectl run --namespace storage redis-server-client --rm --tty -i --restart='Never' \
#     --env REDIS_PASSWORD=$REDIS_PASSWORD \
#    --image docker.io/bitnami/redis:6.0.3-debian-10-r2 -- bash

# 2. Connect using the Redis CLI:
#    redis-cli -h redis-server-master -a $REDIS_PASSWORD
#    redis-cli -h redis-server-slave -a $REDIS_PASSWORD

# To connect to your database from outside the cluster execute the following commands:

#     kubectl port-forward --namespace storage svc/redis-server-master 6379:6379 &
#     redis-cli -h 127.0.0.1 -p 6379 -a $REDIS_PASSWORD

