# Ruby Application - Containerize, Deployment, Orchestration - GitOps

This project showcases a robust solution for containerizing, orchestrating and deployment of applications to multiple clusters using GitOps.

The Ruby application is containerized and deployed to Kubernetes cluster using ArgoCD.

Detailed installation guide with screenshots - ![HERE](./installation_guide.docx)

## Setup

The below components are deployed as part of this setup.

* Ruby Application
* Docker – For containerization
* K3D – To deploy K8s cluster locally and for local container registry.
* Helm – To manifest Kubernetes deployments
* ArgoCD – For Kubernetes deployments

## Tools and pre-requisites

This setup works only in Linux OS having Docker and Bash.

Internet connectivity is required to download docker images from dockerHub.

Below tools are required in you machine for this setup.

* Kubectl - to interact to Kubernetes cluster. https://kubernetes.io/docs/tasks/tools/
* Helm - for helm deployments. Get it ![HERE](https://helm.sh/docs/intro/install/)
* Docker engine
* Bash
* ArgoCD CLI (optional)

## Installation

Installation of this setup is done using bash script.
Below command installs the entire setup.

```bash
./install_setup.sh
```

Clone / Download the GitHub repo to your local - https://github.com/dnoronh/ruby-app-devops.git

The installation usually takes about 1-2 minutes.
Verify if all pods are up and running post the installation.

```bash
kubectl get pods -A
```

The script will perform the below actions
1)	Create K3D cluster
2)	Create docker image for ruby app
3)	Deploy ArgoCD using helm charts
4)	Create ArgoCD applicationSet for ruby app
5)	Port forwarding of ArgoCD service.

## Validation

1)	It will take around 1 min for the setup to complete. Once completed please validate if pods are up and running.
kubectl get pods -A

2)	Validate if able able to reach the ruby application

```bash
curl -kis http://127.0.0.1/healthcheck
```

3)	Validate if you are able to open ArgoCD dashboard using - ![LINK](http://127.0.0.1:9090/)


We can see that image version '1.0' is deployed to Kubernetes by ArgoCD

As best practices for GitOps, we have the manifests in a different Gihub Repo. ArgoCD will be monitoring this repository. - https://github.com/dnoronh/ruby-app-gitops-repo
ArgoCD monitors this repository

## Deploy newer version of Image - GITOPS using ArgoCD

To perform the build and deploy of version 2.0 of the app, we will use GitHub Actions workflow.
GitHub actions pipeline will perform the below steps
1)	Build the docker image
2)	Tag and push the image to registry (this step would be done manually in our case, as we are using a local registry)
3)	Update the image tag in manifest (helm values) – Ideally it is better to use short GIT_SHA for the tags, but in this demo, we will use the tag ‘2.0’ for the newer version.

ArgoCD will sync the changes to the cluster and deploy the new version 2.0

Build 
To demonstrate this in our local cluster, 

Build 2.0 version of docker app from ./docker-build/2 directory by running below command

```bash
./upgrade_app.sh
```

Run the GitHub actions workflow manually by passing app_version as 2.0
This will update the version in the manifest repository, where argocd is monitoring. 

Observe the changes in argoCD or by sending a request to the app. 
You will observe that a rolling deployment to version 2.0 of the app done.

```bash
curl -kis http://127.0.0.1/healthcheck
```

## Cleanup

To cleanup the setup, run the below command

```bash
./install_setup.sh
```

## Feedback

If you see any issues, have any feedback or require any assistance please let me know at delwin.noronha1007@gmail.com