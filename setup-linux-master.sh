set -ex
scriptdir=$(dirname $0)
masterVM=linux-master

# Create the Linux master that will run the k8s control plane
echo "creating linux master as vm name $masterVM ..."
gcloud compute instances create "$masterVM" --image-project=ubuntu-os-cloud --image-family=ubuntu-1604-lts --zone=us-central1-c
sleep 10
gcloud compute scp "$scriptdir/run-this-on-linux-master.sh" "$masterVM:~/run-this-on-linux-master.sh"
gcloud compute ssh "$masterVM" --command  'cd && ./run-this-on-linux-master.sh'
echo "done!"

# get config file for windows worker
echo "downloading config file from master..."
localconfig="/tmp/$masterVM-kube-config"
gcloud compute scp "$masterVM:~/.kube/config" $localconfig
echo "config file for master downloaded to: $localconfig"
