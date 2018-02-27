# set TLS version to be 1.2 (for github.com downloads)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# copy needed files
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

# add C:\k to system path
$env:Path += ";C:\k"
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\k", [EnvironmentVariableTarget]::Machine)

# set KUBECONFIG env var
$env:KUBECONFIG="C:\k\config"
[Environment]::SetEnvironmentVariable("KUBECONFIG", "C:\k\config", [EnvironmentVariableTarget]::User)

# run some debug output to see if we are setup correctly
kubectl config view
kubectl version

echo "make two new powershell windows, go to C:\k\ and run these two processes:"
echo "./start-kubelet.ps1 -ClusterCidr 192.168.0.0/16"
echo "./start-kubeproxy.ps1"
