# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

require File.join(File.dirname(__FILE__), 'config', 'rake-config-local.rb')

$_script = <<SCRIPT
echo "Provisioning Chef Server"
if [ ! -f /usr/install/chef_server_installed.touch ]; then
echo '[be-chef]
name=be-chef
baseurl=#{ REPO_URL }
enabled=1
gpgcheck=0' > /etc/yum.repos.d/be-chef.repo
yum clean all
yum install chef-server-11.0.8 -y
chef-server-ctl reconfigure
mkdir -p /usr/install
touch /usr/install/chef_server_installed.touch
fi
service iptables stop
echo "To run tests on the chef server run this command: chef-server-ctl test"
SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define "chefserver" do |chefserver|

    chefserver.berkshelf.enabled = false

    chefserver.vm.box = "marionette_v2_base"
    chefserver.vm.box_url = BOX_URL

    chefserver.vm.hostname = "chef-server.be.lan"
    chefserver.vm.network "private_network", ip: CHEF_SERVER_IP


    chefserver.vm.provision "shell",
      :inline => $_script

    chefserver.vm.provider("virtualbox") { |vb| vb.name = "chefserver" }
  end

  config.vm.provider :virtualbox do |vb|

    # Don't boot with headless mode
    vb.gui = false

    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "1024"]
  end
end
