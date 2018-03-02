set -e
scriptdir=$(dirname $0)
winVM=windows-node

# Create the windows node to host the pods
echo -n "creating windows node as vm name $winVM ..."
gcloud compute instances create "$winVM" --image-project=windows-cloud --image-family=windows-1709-core-for-containers --machine-type=n1-standard-4 --zone=us-central1-c --network=monterey-pcf-network --subnet=monterey-services-subnet
gcloud compute instances add-tags "$winVM" --tags pivotal-container-service
echo "done!"

echo "now: copy config file to C:\k\ (RDP onto the machine and copy/paste!!),"
echo
echo "then: install docker:"
echo "Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
Install-Package -Name Docker -ProviderName DockerMsftProvider
Restart-Computer -Force"
echo
echo "finally: run run-this-on-windows-node.ps1 on the machine"
