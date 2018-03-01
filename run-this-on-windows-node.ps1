param(
  [Parameter(mandatory=$true)]
  [string]$token,
  [Parameter(mandatory=$true)]
  [string]$workerIp,
  [Parameter(mandatory=$true)]
  [string]$masterIp,
  [string]$clusterCIDR="10.200.0.0/16"
)

$KubeDnsServiceIp = "10.100.200.1"
$hostname = $(hostname)

# define a few strings for config files and scripts
$startKubeletScript = @"
c:\k\kubelet.exe --hostname-override=$hostname --v=2 `
    --pod-infra-container-image=kubeletwin/pause --resolv-conf="" `
    --allow-privileged=true --enable-debugging-handlers `
    --cluster-dns=$KubeDnsServiceIp --cluster-domain=cluster.local `
    --kubeconfig=c:\k\config --hairpin-mode=promiscuous-bridge `
    --image-pull-progress-deadline=20m --cgroups-per-qos=false `
    --enforce-node-allocatable="" `
    --network-plugin=cni --cni-bin-dir="c:\k\cni"
    --cni-conf-dir "c:\k\cni\config" `
    --tls-cert-file=c:\k\kubelet.pem `
    --tls-private-key-file=c:\k\kubelet-key.pem
"@

$startKubeProxyScript = @"
kube-proxy.exe --config C:\k\kubeproxy-config
"@

$kubeConfig = @"
apiVersion: v1
kind: Config
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: https://${masterIP}:8443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubelet
  name: kubelet
current-context: kubelet
users:
- name: kubelet
  user:
    token: "$token"
"@

$kubeProxyConfig = @"
apiVersion: kubeproxy.config.k8s.io/v1alpha1
bindAddress: 0.0.0.0
clientConnection:
  acceptContentTypes: ""
  burst: 10
  contentType: application/vnd.kubernetes.protobuf
  kubeconfig: "c:\\k\\config"
  qps: 5
clusterCIDR: $clusterCIDR
configSyncPeriod: 15m0s
conntrack:
  max: 0
  maxPerCore: 32768
  min: 131072
  tcpCloseWaitTimeout: 1h0m0s
  tcpEstablishedTimeout: 24h0m0s
enableProfiling: false
featureGates: ""
healthzBindAddress: 0.0.0.0:10256
hostnameOverride: $workerIp
iptables:
  masqueradeAll: false
  masqueradeBit: 14
  minSyncPeriod: 0s
  syncPeriod: 30s
ipvs:
  minSyncPeriod: 0s
  scheduler: ""
  syncPeriod: 30s
kind: KubeProxyConfiguration
metricsBindAddress: 127.0.0.1:10249
mode: iptables
oomScoreAdj: -999
portRange: ""
resourceContainer: /kube-proxy
udpTimeoutMilliseconds: 250ms
"@

$overlayConf = @"
{
  "name": "vxlan0",
  "type": "flannel",
  "delegate": {
    "type": "overlay"
  }
}
"@

$flannelNetConf = @"
{
  "Network": "$clusterCIDR",
  "Backend": {
    "name": "overlay0",
    "type": "vxlan",
    "vni": 4096
  }
}
"@
$startFlanneldLocalScript = @"
c:\k\bin\flanneld.exe --kubeconfig-file=c:\k\config --iface=$workerIp --ip-masq=1 --kube-subnet-mgr=1
"@

#TODO: etcd-endpoint should be hostname of etcd endpoint (ends in cf.internal)
# you must modify local windows etc/hosts file to point this domain to linux master node internal IP
# other files scrape from linux worker node
$startFlanneldEtcdScript = @"
flanneld -etcd-endpoints=<%= etcd_endpoints %> `
    --etcd-certfile=C:\k\config\etcd-client.crt `
    --etcd-keyfile=C:\k\config\etcd-client.key `
    --etcd-cafile=C:\k\config\etcd-ca.crt
"@

# set TLS version to be 1.2 (for github.com downloads)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# copy microsoft helper scripts
curl -uri "https://github.com/Microsoft/SDN/archive/master.zip" -outfile master.zip
Expand-Archive master.zip -DestinationPath master
mkdir -Force C:/k/
mv master/SDN-master/Kubernetes/windows/* C:/k/
rm -recurse -force master,master.zip

# create pause image
docker pull microsoft/windowsservercore:1709
docker tag microsoft/windowsservercore:1709 microsoft/windowsservercore:latest
cd C:/k/
docker build -t kubeletwin/pause .

# get exe files for kubernetes windows
curl -uri "https://github.com/cloudfoundry/bosh-agent/raw/master/integration/windows/fixtures/tar.exe" -outfile tar.exe
curl -uri "https://storage.googleapis.com/kubernetes-release/release/v1.9.3/kubernetes-node-windows-amd64.tar.gz" -outfile k.tar.gz
.\tar.exe xf k.tar.gz
mv .\kubernetes\node\bin\*.exe C:\k\
rm -recurse -force kubernetes,k.tar.gz
# write out config files and start scripts
$kubeConfig | Out-File -filepath "C:\k\config"
$kubeProxyConfig | Out-File -filepath "C:\k\kubeproxy-config"
$startKubeletScript | Out-File -filepath "C:\k\start-kubelet.ps1"
$startKubeProxyScript | Out-File -filepath "C:\k\start-kubeproxy.ps1"

# get exe files for cni plugin
mkdir -force c:\k\cni\
cd c:\k\cni\
curl -uri https://storage.googleapis.com/pksw/flannel.exe -outfile flannel.exe
curl -uri https://storage.googleapis.com/pksw/host-local.exe -outfile host-local.exe
curl -uri https://storage.googleapis.com/pksw/overlay.exe -outfile overlay.exe
# write out cni config
mkdir -force c:\k\cni\config
$overlayConf | Out-File -filepath "C:\k\cni\config\overlay.conf"


# get exe file for flanneld
mkdir -force c:\k\bin\
cd c:\k\bin\
curl -uri https://storage.googleapis.com/pksw/flanneld.exe -outfile flanneld.exe
# write out flanneld config & start script
mkdir -Force c:\etc
mkdir -force "c:\etc\kube-flannel"
$flannelNetConfg | Out-File -filepath "C:\etc\kube-flannel\net-conf.json"
$startFlanneldLocalScript | Out-File -filepath "C:\k\start-flanneld-local.ps1"


# add C:\k to system path
$env:Path += ";C:\k"
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\k", [EnvironmentVariableTarget]::Machine)

# set KUBECONFIG env var
$env:KUBECONFIG="C:\k\config"
[Environment]::SetEnvironmentVariable("KUBECONFIG", "C:\k\config", [EnvironmentVariableTarget]::User)

# set NODE_NAME env var for flanneld
$env:NODE_NAME=$hostname
[Environment]::SetEnvironmentVariable("NODE_NAME", $hostname, [EnvironmentVariableTarget]::User)

# run some debug output to see if we are setup correctly
kubectl config view
kubectl version

echo "make three new powershell windows, go to C:\k\ and run these three processes:"
echo "./start-kubelet.ps1"
echo "./start-flanneld-local.ps1"
echo "./start-kubeproxy.ps1"
