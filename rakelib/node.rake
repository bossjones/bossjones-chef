
namespace :node do

  require 'fog'

  desc 'Alias for run'
  task :up do
    Rake::Task[ "node:run" ].execute
  end

  desc 'Destroy and recreate'
  task :reup do
    Rake::Task[ "node:destroy" ].execute
    Rake::Task[ "node:run" ].execute
  end

  desc 'Create or provision the current node'
  task :run do

    vagrant = File.expand_path(File.join(Rake.original_dir, 'Vagrantfile'))

    # Make sure we're in a cookbooks/{cookbook} directory
    unless CHEF_COOKBOOKS_DIR == File.expand_path(File.join(Rake.original_dir, '../'))
      abort("Must be in #{CHEF_COOKBOOKS_DIR}/{cookbook} to run this.")
    end

    # Check for the symlinked Vagrantfile from config
    unless File.exist?(vagrant)
      # This actually has to be a relative path. For some stupid reason.
      FileUtils.symlink( "../../config/Vagrantfile-node" , vagrant )
    end

    # Figure out if the node is up or not.
    output = `cd #{Rake.original_dir}; vagrant status chefnode |  grep chefnode | awk '{ print $2 }';`.strip

    # If it's running, provision it, if not, bring it up
    if output == 'running'
      system("cd #{Rake.original_dir}; vagrant provision chefnode;")
    else
      system("cd #{Rake.original_dir}; vagrant up chefnode;")
    end

  end

  desc 'SSH in'
  task :ssh do
    system("cd #{Rake.original_dir}; vagrant ssh chefnode;")
  end

  desc 'Clear chef cache'
  task :clear_chef_cache do
    system("cd #{Rake.original_dir}; vagrant ssh chefnode -c 'sudo rm /var/chef/cache/* -Rfv';")
  end

  desc 'Destroy current node and remove the chef client'
  task :destroy do

    # Get into the calling dircetory
    system("cd #{ Rake.original_dir }; vagrant destroy chefnode --force;")

    # force delete the client and node
    system("knife client delete #{CHEF_HOST_NAME} <<< $'Y';")
    system("knife node delete #{CHEF_HOST_NAME} <<< $'Y';")

  end

end
