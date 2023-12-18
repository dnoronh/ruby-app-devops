
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
    docker build -t localhost:5000/ruby-app:1.0 ./docker-build/1
    docker push localhost:5000/ruby-app:1.0

#deploy-argocd
    echo ""
    echo "----------DEPLOY ARGOCD---------"
    kubectl config use-context k3d-my-app-cluster
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    helm upgrade -i argocd argo/argo-cd --version 5.35.0 \
    -f ./argocd/values.yaml -n argocd --wait

    sleep 10

    #Modify sync time in argocd to 10s
    kubectl patch configmap argocd-cm -n argocd --type merge --patch '{"data":{"timeout.reconciliation":"10s"}}'
    
    kubectl port-forward svc/argocd-server -n argocd 9090:80 > /dev/null &
    ARGO_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

#deploy-argocd-app:
    kubectl apply -f ./argocd/ruby-app/application-set.yaml

#validation
    echo ""
    echo "----------VALIDATION------------"
    sleep 10
    kubectl get pods -A

    echo ""
    echo "Validating application"
    curl -ksi http://127.0.0.1:80

    echo "Link to Argocd Dashboard - http://127.0.0.1:9090/

    echo ""
    echo "ArgoCD Admin username : admin"
    echo "ArgoCD Admin password : $ARGO_PWD"

    
    echo ""
    echo "Setup completed Successfully.
}



if [ "$1" == "cleanup" ]; then
    cleanup
else
    install
fi
