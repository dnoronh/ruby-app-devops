
#!/bin/bash
set -e

cleanup(){
#cleanup
    echo ""
    echo "----------CLEANUP RESOURCES------"
    k3d cluster delete my-app-cluster
    docker rmi localhost:5000/ruby-app:1.0 || true
    docker rmi localhost:5000/ruby-app:2.0 || true
    sleep 3
    echo "Cleanup Successful"
}


install(){

#Make sure tools are installed
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.6.0 bash
    command -v k3d -v kubectl && command -v helm && command -v docker || { echo "Error: One or more required tools not found."; exit 1; }

    cleanup
#create-app-cluster
    echo ""
    echo "----------CREATE CLUSTER------"
    k3d cluster create --config ./cluster-setup/my-app-cluster.yaml
    kubectl create ns app
    kubectl create ns argocd
    sleep 5

#docker-build:
    echo ""
    echo "----------DOCKER BUILD 1.0------"
    docker build -t localhost:5000/ruby-app:1.0 ./docker-build/1.0
    docker push localhost:5000/ruby-app:1.0
    echo ""
    echo "----------DOCKER BUILD 2.0------"
    docker build -t localhost:5000/ruby-app:2.0 ./docker-build/2.0
    docker push localhost:5000/ruby-app:2.0

#deploy-argocd
    echo ""
    echo "----------DEPLOY ARGOCD---------"
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    echo "Deploying ArgoCD"
    helm upgrade -i argocd argo/argo-cd --version 5.35.0 -n argocd \
    --set dex.image.repository=rancher/mirrored-dexidp-dex \
    --set server.extraArgs[0]="--insecure" --wait

    sleep 4
    #Modify sync time in argocd to 10s
    kubectl patch configmap argocd-cm -n argocd --type merge --patch '{"data":{"timeout.reconciliation":"5s"}}'
    
    kubectl port-forward svc/argocd-server -n argocd 9090:80 > /dev/null &
    ARGO_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

#deploy-argocd-app:
    kubectl apply -f ./argocd/ruby-app/application-set.yaml
    echo ""
    echo "Waiting for ArgoCD to sync the changes..."
    sleep 15

#validation
    echo ""
    echo "----------VALIDATION------------"
    sleep 15
    echo "kubectl get pods -A"
    kubectl get pods -A

    echo ""
    echo "###  Validating application  ###"
    echo ""
    echo "curl -ksi http://127.0.0.1/"
    echo ""
    curl -ksi http://127.0.0.1/
    echo ""
    echo "curl -ksi http://127.0.0.1/healthcheck"
    echo ""
    curl -ksi http://127.0.0.1/healthcheck

    echo ""
    echo "Link to Argocd Dashboard - http://127.0.0.1:9090/"
    echo ""

    echo "ArgoCD Admin username : admin"
    echo "ArgoCD Admin password : $ARGO_PWD"

    echo ""
    echo "Setup completed Successfully."
}


if [ "$1" == "cleanup" ]; then
    cleanup
else
    install
fi
