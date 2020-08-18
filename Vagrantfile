Vagrant.configure("2") do |config|
  (1..3).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.box = "centos/7"
      node.vm.hostname = "node#{i}"
      node.vm.network "private_network", ip:"172.17.8.10#{i}" 
      node.vm.provider "virtualbox" do |vb|
        vb.memory = "3072"
        vb.cpus = "1"
        vb.name = "node#{i}"
      end
      node.vm.provision "shell",path:"pre.sh"
    end
  end
end
