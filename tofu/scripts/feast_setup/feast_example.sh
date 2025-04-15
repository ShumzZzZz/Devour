#!/bin/bash

kubectl create ns feast
kubectl config set-context --current --namespace feast

kubectl label nodes <nodes> dedicated=featurestore
kubectl taint nodes <nodes> dedicated=featurestore:NoExecute

curl -sSLO https://raw.githubusercontent.com/ShumzZzZz/Devour/refs/heads/provision-with-opentofu/tofu/scripts/feast_setup/prerequisite_setup.yaml
kubectl apply -f prerequisite_setup.yaml

kubectl wait --for=condition=available --timeout=5m deployment/redis
kubectl wait --for=condition=available --timeout=5m deployment/postgres

curl -sSLO https://raw.githubusercontent.com/ShumzZzZz/Devour/refs/heads/provision-with-opentofu/tofu/scripts/feast_setup/feast_operator_install.yaml
kubectl apply -f feast_operator_install.yaml

kubectl wait --for=condition=available --timeout=5m deployment/feast-operator-controller-manager -n feast

curl -sSLO https://raw.githubusercontent.com/ShumzZzZz/Devour/refs/heads/provision-with-opentofu/tofu/scripts/feast_setup/feast.yaml
kubectl apply -f feast.yaml

kubectl wait --for=condition=available --timeout=8m deployment/feast-example

kubectl exec deploy/postgres -- psql -h localhost -U feast feast -c '\dt'

kubectl exec deployment/feast-example -itc online -- feast version