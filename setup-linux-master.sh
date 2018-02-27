
# Create the Linux master that will run the k8s control plane
gcloud compute instances create new-linux-master --image-project=ubuntu-os-cloud --image-family=ubuntu-1604-lts --zone=us-central1-c
# TODO: scp helper script to vm && use gcloud compute ssh --command to run the script


# Create the windows node to host the pods
#gcloud compute instances create new-windows-node --image-project=windows-cloud --image-family=windows-1709-core-for-containers --zone=us-central1-c


