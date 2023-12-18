

install: create-app-cluster docker-build deploy-argocd deploy-argocd-app


cleanup:
    k3d cluster delete my-app-cluster
    # docker rmi localhost:5000/ruby-app:1.0 || true
    # docker rmi localhost:5000/ruby-app:2.0 || true
    @sleep 3
    echo "Cleanup Successful"

create-app-cluster: cleanup
    k3d cluster create --config ./cluster-setup/my-app-cluster.yaml
    kubectl create ns app
    kubectl create ns argocd
    @sleep 5

docker-build:
    docker build -t localhost:5000/ruby-app:1.0 ./docker-build
    docker push localhost:5000/ruby-app:1.0

docker-build-2:
    docker build -t localhost:5000/ruby-app:2.0 ./docker-build
    docker push localhost:5000/ruby-app:2.0
    ./docker-build/update-tag.sh "2.0"

deploy-argocd:
    kubectl config use-context k3d-my-app-cluster
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    helm upgrade -i argocd argo/argo-cd --version 5.35.0 \
    -f ./argocd/values.yaml -n argocd --set configs.cm.admin.enabled=false
    sleep 15
    kubectl patch configmap argocd-cm -n argocd --type merge --patch '{"data":{"admin.enabled":"false"}}'

    kubectl port-forward svc/argocd-server -n argocd 9090:80 > /dev/null 2>&1 &
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    # echo "ARGOCD password = ${kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d}"

deploy-argocd-app:
    kubectl apply -f ./argocd/ruby-app/application.yaml


[CustomResourceDefinition] applications.argoproj.io
[CustomResourceDefinition] applicationsets.argoproj.io
[CustomResourceDefinition] appprojects.argoproj.io