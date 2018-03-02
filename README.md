Start by `gcloud auth login`'ing in to your gcloud account that has an Ops manager + PKS tile installed.
Make sure to target the services network that ops manager is using.

now...

1. run `./setup-windows-node.sh` (change network name / subnet name in script to match yours)
1. click the "set password" button, then click "RDP" in the cloud console to get into the machine
   (make sure to save your password somewhere! sometimes kubernetes messes with GCP ability to
   reset the password)
1. click the "RDP" button to get in (you may need to open up firewall port to your machine)
1. run `powershell.exe` then run the docker install commands specified in `./setup-windows-node.sh`,
   wait for machine to reboot
1. `ssh` into your ops manager VM, then `bosh ssh` into a linux node from your PKS cluster.
   find the kubeconfig file (`ps aux | grep kubelet` to see what config file it is using).
   Get the token.
1. while you are `ssh`'d into the worker, grab the files `kubelet.pem` and `kubelet-key.pem`
1. RDP back in, copy in the script `run-this-on-windows-node.ps1`. run it. it will ask you
   to put in the token you just got from the linux node, and also the windows VM internal
   IP, and the master linux node IP.
