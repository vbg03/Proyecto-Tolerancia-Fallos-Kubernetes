# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  if Vagrant.has_plugin? "vagrant-vbguest"
    config.vbguest.no_install  = true
    config.vbguest.auto_update = false
    config.vbguest.no_remote   = true
  end

  config.vm.define :k8sServer do |k8sServer|
    k8sServer.vm.box = "bento/ubuntu-22.04"
    k8sServer.vm.network :private_network, ip: "192.168.100.10"
    k8sServer.vm.hostname = "k8sServer"
    
    # Kubernetes necesita más recursos
    k8sServer.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"  # 4GB RAM
      vb.cpus = 2
    end
    
    # Script de provisión
    k8sServer.vm.provision "shell", path: "setup-k8s.sh"
  end
  config.vm.boot_timeout = 600
end