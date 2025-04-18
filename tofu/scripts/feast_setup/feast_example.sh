#!/bin/bash

kubectl create ns feast
kubectl config set-context --current --namespace feast

#kubectl label nodes ip-10-10-1-140 dedicated=featurestore
#kubectl label nodes ip-10-10-1-175 dedicated=featurestore
#kubectl label nodes ip-10-10-1-226 dedicated=featurestore
#kubectl taint nodes ip-10-10-1-140 dedicated=featurestore:NoExecute
#kubectl taint nodes ip-10-10-1-175 dedicated=featurestore:NoExecute
#kubectl taint nodes ip-10-10-1-226 dedicated=featurestore:NoExecute

kubectl label nodes <nodes> dedicated=featurestore
kubectl taint nodes <nodes> dedicated=featurestore:NoExecute


curl -sSLO https://raw.githubusercontent.com/ShumzZzZz/Devour/refs/heads/provision-with-opentofu/tofu/scripts/feast_setup/feast_scheduling_pref.yaml
helm install kyverno kyverno/kyverno -n kyverno --create-namespace \
  --values feast_scheduling_pref.yaml

curl -sSLO https://raw.githubusercontent.com/ShumzZzZz/Devour/refs/heads/provision-with-opentofu/tofu/scripts/feast_setup/kyverno_cluster_policy.yaml
kubectl apply -f kyverno_cluster_policy.yaml

curl -sSLO https://raw.githubusercontent.com/ShumzZzZz/Devour/refs/heads/provision-with-opentofu/tofu/scripts/feast_setup/prerequisite_setup.yaml
kubectl apply -f prerequisite_setup.yaml

kubectl wait --for=condition=available --timeout=5m deployment/redis-feast
kubectl wait --for=condition=available --timeout=5m deployment/postgres-feast

curl -sSLO https://raw.githubusercontent.com/ShumzZzZz/Devour/refs/heads/provision-with-opentofu/tofu/scripts/feast_setup/feast_operator_install.yaml
kubectl apply -f feast_operator_install.yaml

kubectl wait --for=condition=available --timeout=5m deployment/feast-operator-controller-manager -n feast

curl -sSLO https://raw.githubusercontent.com/ShumzZzZz/Devour/refs/heads/provision-with-opentofu/tofu/scripts/feast_setup/feast.yaml
kubectl apply -f feast.yaml

kubectl wait --for=condition=available --timeout=8m deployment/feast-example

kubectl exec deployment/postgres-feast -- psql -h localhost -U feastuser feastdb -c '\dt'
kubectl exec deployment/feast-example -itc online -- feast version



kubectl delete -f feast.yaml
kubectl delete -f feast_operator_install.yaml
kubectl delete -f prerequisite_setup.yaml
