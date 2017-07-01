# Get the docker container which includes aws-cli, kops, kubectl, etc.
# You may need to be root or equivalent, or sodu docker commands.

docker pull fluxcapacitor/kubernetes:master

# first time
docker run -itd --name=kubernetes-master --privileged --net=host -v /home/USERNAME/.ssh:/root/.ssh fluxcapacitor/kubernetes:master
# other times
docker start kubernetes-master

docker exec -it kubernetes-master bash
# Now you're in the docker container
apt-get install uuid jq dnsutils

# Configure the aws client with secrets you can get from AWS
aws configure


export KOPS_STATE_STORE=s3://pydata-2.homenet.org
export CLUSTER_NAME=pydata-2.homenet.org

# You need to run this only once, to create the S3 bucket.
aws s3 mb ${KOPS_STATE_STORE}


# Here you're creating an amazon route53 entry, to handle dns requests to your cluster.
export ID=`uuid`
aws route53 create-hosted-zone --name ${CLUSTER_NAME} --caller-reference $ID | jq .DelegationSet.NameServers

# if route53 entry is already there and you need to see the name servers:
aws route53 list-hosted-zones | jq '.HostedZones[] | select(.Name=="ancud-pipeline-test.homenet.org.") | .Id'
#replace the --id value with the output from above
aws route53 get-hosted-zone --id "COPY_FROM_ABOVE" | jq .DelegationSet.NameServer
# user one of them to set an NS record on http://freedns.afraid.org/subdomain/

# Create the cluster definitions on the S3 bucket.
kops create cluster \
    --cloud aws \
    --cloud-labels "project=pipeline" \
    --dns public \
    --dns-zone ${CLUSTER_NAME} \
    --ssh-public-key ~/.ssh/id_rsa.pub \
    --networking flannel \
    --master-zones eu-central-1a \
    --master-size t2.medium \
    --zones eu-central-1a \
    --node-count 2 \
    --node-size r3.2xlarge \
    --node-tenancy dedicated \
    --kubernetes-version 1.7.0-beta.2 \
    --image kope.io/k8s-1.6-debian-jessie-amd64-hvm-ebs-2017-05-02 \
    --alsologtostderr \
    --log_dir logs \
    --v 5 \
    --state ${KOPS_STATE_STORE} \
    --name ${CLUSTER_NAME}


kops edit ig --name=${CLUSTER_NAME} nodes

spec:
# FROM HERE
  rootVolumeSize: 200
  rootVolumeType: gp2
  kubelet:
    featureGates:
      Accelerators: "true"
  kubernetesVersion: v1.7.0-rc.1
  nodeLabels:
    gpu: "false"
# TO HERE

kops get ig --state ${KOPS_STATE_STORE} --name ${CLUSTER_NAME}
kops update cluster ${CLUSTER_NAME} --yes

kubectl config set-cluster ${CLUSTER_NAME} --insecure-skip-tls-verify=true
# add kubernetes dashboard
kubectl create -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/kubernetes-dashboard/v1.6.0.yaml

#get password 
kubectl config view

kubectl cluster-info

# add weave-scope
kubectl create -f https://cloud.weave.works/k8s/scope.yaml?v=1.3.0
kubectl port-forward -n default "$(kubectl get -n default pod --selector=weave-scope-component=app -o jsonpath='{.items..metadata.name}')" 4040

#setup pipeline
export PIO_VERSION=v1.2.0

wget -O - https://raw.githubusercontent.com/fluxcapacitor/pipeline/$PIO_VERSION/scripts/cluster/deploy | PIO_COMMAND=create bash

wget -O - https://raw.githubusercontent.com/fluxcapacitor/pipeline/$PIO_VERSION/scripts/cluster/svc | PIO_COMMAND=create bash

# check deployments and wait
kubectl get pod

kubectl get deploy 

kubectl get svc 

# wait
kubectl get svc -w

# describe services
kubectl describe svc jupyterhub
