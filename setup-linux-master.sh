set -ex
scriptdir=$(dirname $0)
masterVM=linux-master

# Create the Linux master that will run the k8s control plane
gcloud compute instances create "$masterVM" --image-project=ubuntu-os-cloud --image-family=ubuntu-1604-lts --zone=us-central1-c
gcloud compute scp "$scriptdir/run-this-on-linux-master.sh" "$masterVM:~/run-this-on-linux-master.sh"
gcloud compute ssh "$masterVM" --command  'cd && ./run-this-on-linux-master.sh'
gcloud compute scp "$masterVM:~/.kube/config" "/tmp/$masterVM-kube-config"

# Create the windows node to host the pods
#gcloud compute instances create new-windows-node --image-project=windows-cloud --image-family=windows-1709-core-for-containers --zone=us-central1-c


