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
    
    # Kubernetes + Istio necesita más recursos
    k8sServer.vm.provider "virtualbox" do |vb|
      vb.memory = "6144"  # 6GB RAM (aumentado)
      vb.cpus = 4         # 4 CPUs (aumentado)
      vb.customize ["modifyvm", :id, "--ioapic", "on"]
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    end
    
    # Script de provisión
    k8sServer.vm.provision "shell", path: "setup-k8s.sh"
  end
  
  config.vm.boot_timeout = 600
end