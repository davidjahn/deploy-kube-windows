set -e
scriptdir=$(dirname $0)
winVM=windows-node

# Create the windows node to host the pods
echo -n "creating windows node as vm name $winVM ..."
gcloud compute instances create "$winVM" --image-project=windows-cloud --image-family=windows-1709-core-for-containers --zone=us-central1-c
echo "done!"

echo "now: copy config file to C:\k\ (RDP onto the machine and copy/paste!!),"
echo "install docker (https://docs.microsoft.com/en-us/virtualization/windowscontainers/kubernetes/getting-started-kubernetes-windows), and"
echo "run run-this-on-windows-node.ps1 on the machine"
