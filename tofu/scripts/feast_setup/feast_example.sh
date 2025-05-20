#!/bin/bash

k create ns feast
k config set-context --current --namespace feast

k get nodes --no-headers | awk '$3 != "control-plane" {print $1}' | while read node; do
  k label node "$node" dedicated=featurestore --overwrite
  k taint node "$node" dedicated=featurestore:NoExecute --overwrite
done


curl -sSLO https://raw.githubusercontent.com/ShumzZzZz/devour/refs/heads/main/tofu/scripts/feast_setup/feast_scheduling_pref.yaml
helm install kyverno kyverno/kyverno -n kyverno --create-namespace \
  --values feast_scheduling_pref.yaml

k wait --for=condition=available --timeout=5m deployment/kyverno-admission-controller -n kyverno
k wait --for=condition=available --timeout=5m deployment/kyverno-background-controller -n kyverno
k wait --for=condition=available --timeout=5m deployment/kyverno-cleanup-controller -n kyverno
k wait --for=condition=available --timeout=5m deployment/kyverno-reports-controller -n kyverno

curl -sSLO https://raw.githubusercontent.com/ShumzZzZz/devour/refs/heads/main/tofu/scripts/feast_setup/kyverno_cluster_policy.yaml
k apply -f kyverno_cluster_policy.yaml


git clone https://github.com/prometheus-operator/kube-prometheus.git
k apply --server-side -f kube-prometheus/manifests/setup
k wait \
	--for condition=Established \
	--all CustomResourceDefinition \
	--namespace=monitoring
k apply -f kube-prometheus/manifests/
# https://github.com/prometheus-operator/kube-prometheus/blob/main/docs/access-ui.md
# kp --namespace monitoring svc/grafana 3000



curl -sSLO https://raw.githubusercontent.com/ShumzZzZz/devour/refs/heads/main/tofu/scripts/feast_setup/prerequisite_setup.yaml
k apply -f prerequisite_setup.yaml

k wait --for=condition=available --timeout=5m deployment/redis-feast
k wait --for=condition=available --timeout=5m deployment/postgres-feast

curl -sSL https://raw.githubusercontent.com/feast-dev/feast/refs/heads/master/infra/feast-operator/dist/install.yaml -o feast_operator_install.yaml
k apply -f feast_operator_install.yaml

k wait --for=condition=available --timeout=5m deployment/feast-operator-controller-manager -n feast-operator-system

curl -sSLO https://raw.githubusercontent.com/ShumzZzZz/devour/refs/heads/main/tofu/scripts/feast_setup/feast.yaml
k apply -f feast.yaml
sleep 3
k wait --for=condition=available --timeout=8m deployment/feast-example






k exec deployment/postgres-feast -- psql -h localhost -U feastuser feastdb -c '\dt'
k exec deployment/feast-example -itc online -- bash # feast version


# cronjob & customization
kubectl get feast/example -o jsonpath='{.status.applied.cronJob.containerConfigs.commands}'
feast materialize-incremental $(date -u +'%Y-%m-%dT%H:%M:%S')
#feast materialize '2022-01-01T00:00:00' $(date -u +"%Y-%m-%dT%H:%M:%S")
#kubectl patch feast/example --patch '{"spec":{"cronJob":{"containerConfigs":{"commands":["pip install -r ../requirements.txt","cd ../ && python run.py"]}}}}' --type=merge

k create job --from=cronjob/feast-example feast-example-apply
k wait --for=condition=complete --timeout=8m job/feast-example-apply
k logs job/feast-example-apply --all-containers=true

# port-forward
kp svc/feast-example-registry 8001:80 &
# kp svc/postgre-service 8001:5432 &
kp svc/feast-example-online 8002:80 &
kp svc/feast-example-ui 8003:80 &

kill "$(lsof -i :8001 | awk 'NR>1 {print $2}' | sort -nu)"
kill "$(lsof -i :8002 | awk 'NR>1 {print $2}' | sort -nu)"
kill "$(lsof -i :8003 | awk 'NR>1 {print $2}' | sort -nu)"

helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
	--create-namespace --namespace kubernetes-dashboard \
	--set metricsScraper.enabled=true

kubectl create serviceaccount admin-user -n kubernetes-dashboard
kubectl create clusterrolebinding admin-user-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=kubernetes-dashboard:admin-user
kubectl -n kubernetes-dashboard create token admin-user


curl -L https://istio.io/downloadIstio | sh -
cd $(ls | grep istio)
export PATH="$PATH:$PWD/bin"


cat <<EOF | kubectl apply -f -
apiVersion: projectcalico.org/v3
kind: FelixConfiguration
metadata:
  name: default
spec:
  # Disable connect-time load balancing entirely
  bpfConnectTimeLoadBalancing: Disabled
EOF

kubectl -n calico-system rollout restart daemonset calico-node

cat <<EOF > istio-cni.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    cni:
      namespace: istio-system
      enabled: true
EOF
istioctl install -f istio-cni.yaml -y

kubectl -n istio-system patch svc istio-ingressgateway \
  -p '{
    "spec": {
      "type": "NodePort",
      "ports": [
        {
          "name": "status-port",
          "port": 15021,
          "targetPort": 15021,
          "nodePort": 31475
        },
        {
          "name": "http2",
          "port": 80,
          "targetPort": 8080,
          "nodePort": 32258
        },
        {
          "name": "https",
          "port": 443,
          "targetPort": 8443,
          "nodePort": 30397
        }
      ]
    }
  }'

curl -sSLO https://raw.githubusercontent.com/ShumzZzZz/devour/refs/heads/main/tofu/scripts/feast_setup/feast-gateway.yaml
k apply -f feast-gateway.yaml

curl -sSLO https://raw.githubusercontent.com/ShumzZzZz/devour/refs/heads/main/tofu/scripts/feast_setup/istio-vs.yaml
k apply -f istio-vs.yaml

#curl -sSLO https://raw.githubusercontent.com/ShumzZzZz/devour/refs/heads/main/tofu/scripts/feast_setup/istio-hostport-ingress.yaml
#istioctl install -f istio-hostport-ingress.yaml -y


k delete --ignore-not-found=true -f kube-prometheus/manifests/ -f kube-prometheus/manifests/setup
k delete -f feast.yaml
k delete -f feast_operator_install.yaml
k delete -f prerequisite_setup.yaml


