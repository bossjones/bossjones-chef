# NOTE, this is for multi-vm configs
require File.join(File.dirname(__FILE__), 'stacks', 'global-stack-config-example.rb')
####

HOME_DIR = File.expand_path('~')

# The top of the repository checkout
unless defined?(TOPDIR)
  TOPDIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))
end

GIT_ACCESS_TOKEN = 'token-goes-here'

CHEF_USER_NAME = 'user'

CHEF_LOCAL_SUFFIX = '-local'

# URL of the box
BOX_URL = "http://files.be.lan:8080/vbox/distros/marionette/marionette_v2_base.box"

# Behance Repo ( for the chef server rpm )
REPO_URL = "http://files.be.lan:8080/repos/berepo1/be-chef/centos/6/$basearch"

# The chef server IP address
CHEF_SERVER_IP = "192.168.57.101"

CHEF_SERVER_HOSTNAME = "chef-server.be.lan"

CHEF_ORG          = 'bossjoneschef'

CHEF_SERVER_URL      = "https://api.opscode.com/organizations/#{CHEF_ORG}"

# Reference to the .chef directory
CHEF_CONFIG_DIR = File.join(HOME_DIR, '.chef')

# Reference to cookbooks directory
CHEF_COOKBOOKS_DIR = File.expand_path( "cookbooks" )

# Chef validator key
CHEF_VAL_KEY_PATH = File.join(CHEF_CONFIG_DIR, "chef-validator#{CHEF_LOCAL_SUFFIX}.pem")

# Chef node name
CHEF_HOST_NAME = "chefnode"

# Branch to be built out
BUILD_BRANCH = 'master'

# Chef log level output by Vagrant
CHEF_LOG_LEVEL = 'debug'

# Chef environment
CHEF_ENVIRONMENT = 'dev'

# Run list. Really only used for Berkshelf runs
CHEF_RUN_LIST = [
        "bebootstrap"
      ]

CUSTOM_JSON_DATA = {
        "chef_environment" => "dev",
        "normal" => {
            "be" => {
                "location" => "rackspace"
            }
        }
}


# multi vm

STACK_SELECTED = "bedeployserver"

STACKS_DIR = File.join(TOPDIR, 'config/stacks')

