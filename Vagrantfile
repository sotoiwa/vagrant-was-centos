# -*- mode: ruby -*-
# vi: set ft=ruby :

node_num=2

Vagrant.configure(2) do |config|

  (1..node_num).each do |i|

    server_name = "node#{i}"

    config.vm.define server_name do |server|

      # ホスト名
      server.vm.hostname = server_name
      # ノードのベースOSを指定
      server.vm.box = "centos/7"
      # ネットワークを指定
      private_ip = "192.168.33.#{i+40}"
      server.vm.network "private_network", ip: private_ip

      # config.vm.synced_folder ".", "/vagrant", type:"virtualbox"

      if Vagrant.has_plugin?("vagrant-vbguest")
        config.vbguest.auto_update = false
      end

      # ノードのスペックを指定
      server.vm.provider "virtualbox" do |vb|
        if i == 1 then
          vb.memory = 2048
        else
          vb.memory = 1024
        end
      end

    end
  end
end
