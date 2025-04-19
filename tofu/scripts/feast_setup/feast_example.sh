#!/bin/bash
alias k='kubectl'
alias kd='kubectl describe'

k create ns feast
k config set-context --current --namespace feast

k get nodes --no-headers | awk '$3 != "control-plane" {print $1}' | while read node; do
  k label node "$node" dedicated=featurestore --overwrite
  k taint node "$node" dedicated=featurestore:NoExecute --overwrite
done


curl -sSLO https://raw.githubusercontent.com/ShumzZzZz/Devour/refs/heads/provision-with-opentofu/tofu/scripts/feast_setup/feast_scheduling_pref.yaml
helm install kyverno kyverno/kyverno -n kyverno --create-namespace \
  --values feast_scheduling_pref.yaml

k wait --for=condition=available --timeout=5m deployment/kyverno-admission-controller -n kyverno
k wait --for=condition=available --timeout=5m deployment/kyverno-background-controller -n kyverno
k wait --for=condition=available --timeout=5m deployment/kyverno-cleanup-controller -n kyverno
k wait --for=condition=available --timeout=5m deployment/kyverno-reports-controller -n kyverno

curl -sSLO https://raw.githubusercontent.com/ShumzZzZz/Devour/refs/heads/provision-with-opentofu/tofu/scripts/feast_setup/kyverno_cluster_policy.yaml
k apply -f kyverno_cluster_policy.yaml

curl -sSLO https://raw.githubusercontent.com/ShumzZzZz/Devour/refs/heads/provision-with-opentofu/tofu/scripts/feast_setup/prerequisite_setup.yaml
k apply -f prerequisite_setup.yaml

k wait --for=condition=available --timeout=5m deployment/redis-feast
k wait --for=condition=available --timeout=5m deployment/postgres-feast

curl -sSL https://raw.githubusercontent.com/feast-dev/feast/refs/heads/master/infra/feast-operator/dist/install.yaml -o feast_operator_install.yaml
k apply -f feast_operator_install.yaml

k wait --for=condition=available --timeout=5m deployment/feast-operator-controller-manager -n feast

curl -sSLO https://raw.githubusercontent.com/ShumzZzZz/Devour/refs/heads/provision-with-opentofu/tofu/scripts/feast_setup/feast.yaml
k apply -f feast.yaml

k wait --for=condition=available --timeout=8m deployment/feast-example

k exec deployment/postgres-feast -- psql -h localhost -U feastuser feastdb -c '\dt'
k exec deployment/feast-example -itc online -- feast version


k delete -f feast.yaml
k delete -f feast_operator_install.yaml
k delete -f prerequisite_setup.yaml
