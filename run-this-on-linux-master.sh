set -x
# From: https://github.com/MicrosoftDocs/Virtualization-Documentation/blob/live/virtualization/windowscontainers/kubernetes/creating-a-linux-master.md

# Install basic dependencies
sudo apt-get install -y curl git build-essential docker.io conntrack python2.7

# Download helper scripts
mkdir ~/kube
mkdir ~/kube/bin
git clone https://github.com/Microsoft/SDN /tmp/k8s 
cd /tmp/k8s/Kubernetes/linux
chmod -R +x *.sh
chmod +x manifest/generate.py
mv * ~/kube/

# Install Linux Binaries
wget -O kubernetes.tar.gz https://github.com/kubernetes/kubernetes/releases/download/v1.9.1/kubernetes.tar.gz
tar -vxzf kubernetes.tar.gz 
cd kubernetes/cluster 
# TODO
# follow the prompts from this command, the defaults are generally fine:
echo Y | ./get-kube-binaries.sh
cd ../server
tar -vxzf kubernetes-server-linux-amd64.tar.gz 
cd kubernetes/server/bin
cp hyperkube kubectl ~/kube/bin/

# TODO .profile
PATH="$HOME/kube/bin:$PATH"

# Install CNI Plugins
DOWNLOAD_DIR="${HOME}/kube/cni-plugins"
CNI_BIN="/opt/cni/bin/"
mkdir ${DOWNLOAD_DIR}
cd $DOWNLOAD_DIR
curl -L $(curl -s https://api.github.com/repos/containernetworking/plugins/releases/latest | grep browser_download_url | grep 'amd64.*tgz' | head -n 1 | cut -d '"' -f 4) -o cni-plugins-amd64.tgz
tar -xvzf cni-plugins-amd64.tgz
sudo mkdir -p ${CNI_BIN}
rm cni-plugins-amd64.tgz
sudo cp -r * ${CNI_BIN}
ls ${CNI_BIN}

# TODO: Get local IP addr
MASTER_IP=10.128.0.2

# Generate cert
cd ~/kube/certs
chmod u+x generate-certs.sh
./generate-certs.sh $MASTER_IP

# Something something system pods?
# TODO this is the first time cluster prefix shows up
cd ~/kube/manifest
./generate.py $MASTER_IP --cluster-cidr 192.168.0.0/16
rm generate.py # so k8s doesn't think it's a config file

# Generate kube config
cd ~/kube
./configure-kubectl.sh $MASTER_IP
# Put kubeconfig in expected location
mkdir ~/kube/kubelet
sudo cp ~/.kube/config ~/kube/kubelet/
# TODO - we need to download this file in order to upload it to the windows node later


## START TWO LONG RUNNING PROCESSES

# start kubeproxy
cd ~/kube
sudo ./start-kubeproxy.sh 192.168 > ~/kubeproxy.log 2>&1 &

# start kubelet
cd ~/kube
sudo ./start-kubelet.sh > ~/kubelet-log 2>&1 &
