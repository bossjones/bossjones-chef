#
# Rakefile for Chef Server Repository
#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'rubygems'
require 'json'
require 'fileutils'
require 'net/scp'
require 'yaml'
require 'versionomy'
require 'chef'
require 'chef/cookbook/metadata'
require 'github_api'

# Load constants + local constants from rake config file.
require File.join(File.dirname(__FILE__), 'config', 'rake-config.rb')

local_config = File.join( File.dirname(__FILE__), 'config', 'rake-config-local.rb' )

if ! File.exists? local_config
  puts "WARNING: Please create your local rake config file. You can run\ncp config/rake-config-local-example.rb config/rake-config-local.rb"
  puts "WARNING: Loading config/rake-config-local-example.rb"
  require File.join( File.dirname(__FILE__), 'config', 'rake-config-local-example.rb' )
else
  require local_config
end

# Detect the version control system and assign to $vcs. Used by the update
# task in chef_repo.rake (below). The install task calls update, so this
# is run whenever the repo is installed.
#
# Comment out these lines to skip the update.

if File.directory?(File.join(TOPDIR, ".svn"))
  $vcs = :svn
elsif File.directory?(File.join(TOPDIR, ".git"))
  $vcs = :git
end

#######################################################################
# Behance Tasks
#
# Originally used popen3 so that I can capture stdout to manipulate this,
#   but then transitioned to net-scp to just copy them down.
namespace :server do

  desc 'All new server tasks'
  task :all => [
      "server:check_hosts",
      "server:create",
      "server:pems",
      "server:user",
      "server:kniferb",
      "server:update_databags",
      "server:update_environments",
      "server:update_roles",
  ]

  desc 'Check hosts file for a route to the chef server (Mac OS only)'
  task :check_hosts do

    result = open('/private/etc/hosts').grep(/#{CHEF_SERVER_HOSTNAME}/)

    if result.length > 0
      puts "Hosts file OK"
    else
      puts "Hosts file missing chef server. Please add and retry. \n#{CHEF_SERVER_IP}  #{CHEF_SERVER_HOSTNAME}"
      abort()
    end

  end

  desc 'Start the chef server via vagrant'
  task :create do

    system("vagrant up chefserver")

  end

  desc 'Grab the certificates off the server'
  task :pems do

    get_pems

  end

  desc 'Create a user on the server'
  task :user do

    create_user

  end

  desc 'Create the knife file for the user'
  task :kniferb do

    create_kniferb

  end

  desc 'Upload databags'
  task :update_databags do

    data_bags_path   = File.join(TOPDIR, 'data_bags')

    Dir.foreach(data_bags_path) do |data_bag|
      next if data_bag == '.' or data_bag == '..' or data_bag == '.git' or data_bag == 'README.md'

      puts "databag: #{data_bag}"
      system("knife data bag create #{data_bag}")

      items_path = File.join(data_bags_path, data_bag)
      Dir.foreach(items_path) do |data_bag_item|
        next if data_bag_item == '.' or data_bag_item == '..'

        data_bag_item_path = File.join(items_path, data_bag_item)

        system("knife data bag from file #{data_bag} #{data_bag_item_path}")

      end

    end

  end

  desc 'Upload Environments'
  task :update_environments do

    chef_environments_path   = File.join(TOPDIR, 'environments')
    chef_environments_names  = Dir.entries(chef_environments_path)

    %w{ . .. README.md example.json}. each do |exclude|
      chef_environments_names.delete(exclude)
    end

    print "chef_environments_names: #{chef_environments_names}\n\n"
    chef_environments_names.each do |envs|

      chef_environments_absolute_path = File.absolute_path("#{chef_environments_path}/#{envs}")

      is_json  = File.extname("#{envs}")

      if is_json == ".json"
        is_json = File.basename("#{chef_environments_path}/#{envs}",".json")
        system("knife environment from file #{chef_environments_path}/#{envs}")
      end

    end

  end

  desc "Update Roles"
  task :update_roles do

    system("knife upload roles")

  end

  desc 'Smart cookbook upload, will filter on tag or cookbook name'
  task :update_cookbooks, :filter_input do |t, args|
    filter_input = args[:filter_input] || 'all'

    # todo: check if the manifest file is up to date.

    repos = YAML::load(File.open(File.join(TOPDIR, 'Repos.yml')))
    manifile = File.join(TOPDIR, 'Manifest.yml')

    if !File.exists?(manifile)
      Rake::Task[ "repo:manifest_build" ].execute
    end

    manifest = YAML::load_file(manifile)

    repos.each do |repo|

      if filter(filter_input, repo) then

        puts "*** #{repo['name']}"
        upload_cookbook_dependencies(repo, manifest)

      end

    end

  end

  desc 'Build: keep your server up to date. Defaults to BUILD_BRANCH in rake-local'
  task :build do
    # Get up to date from source control
    case $vcs
    when :svn
      sh %{svn up}
    when :git
      puts "Checking out #{BUILD_BRANCH}"
      sh "git checkout #{BUILD_BRANCH}"
      sh "git pull"
    end
    # Push cookbooks, roles, and databags onto the server
    sh 'knife cookbook upload --all --force'
    Rake::Task[ "databag:upload_all" ].execute
    Rake::Task[ :roles ].execute
  end

end

# When iterating through repos, filter some out based on tags
#   OR only perform the task on one.
def filter(filter, repo)

  return ( (filter == 'all') || ( repo.has_key?('tags') && repo['tags'].include?(filter) ) || repo['name'] == filter )

end

def create_kniferb

  file_name = "#{ CHEF_CONFIG_DIR }/knife#{ CHEF_LOCAL_SUFFIX }.rb"
  file_lines = [
    "log_level                :info",
    "log_location             STDOUT",
    "node_name                '#{ CHEF_USER_NAME }'",
    "client_key               '#{ CHEF_CONFIG_DIR }/#{ CHEF_USER_NAME }#{ CHEF_LOCAL_SUFFIX }.pem'",
    "validation_client_name   'chef-validator#{ CHEF_LOCAL_SUFFIX }'",
    "validation_key           '#{ CHEF_VAL_KEY_PATH }'",
    "chef_server_url          '#{ CHEF_SERVER_URL }'",
    "syntax_check_cache_path  '#{ CHEF_CONFIG_DIR }/syntax_check_cache'",
    "cookbook_path            [ '#{ CHEF_COOKBOOKS_DIR }' ]",
    "",
  ].join("\n")
  File.open(file_name, 'w') {|f| f.write( file_lines ) }

  puts "created #{ file_name }"

end

def normalize_version(version_str)

  return Versionomy.parse( version_str.sub('v', '').sub('~>', '').strip )

end

def upload_cookbook_dependencies(repo, manifest)

  path = File.join( CHEF_COOKBOOKS_DIR, repo['name'] )

  # for the repo figure out the dependencies, and their versions
  metadata = Chef::Cookbook::Metadata.new
  metadata.from_file( File.join( path, 'metadata.rb' ) )

  metadata.dependencies.each do |cookbook, version|

    # Cookbook versions are expanded out to defaults, so we can rely on both these being here.

    # puts "#{cookbook}"
    # puts "#{version}"

    # attempt to figure out what the dependency really needs
    dependency_decl = version.split

    dependency_operator = dependency_decl[0]
    dependency_version = dependency_decl[1]

    required_version = normalize_version( dependency_version )

    unless manifest.include?( cookbook.to_sym )
      abort("#{cookbook} not in the manifest.\nIf the cookbook is available in the organziation, please run \nrake repo:manifest_build")
    end

    version_exists = manifest[ cookbook.to_sym ].include?( required_version.to_s )

    # If the cookbook exists in the manifest,
    # look for a version that satisfies the dependency
    if manifest.has_key?( cookbook.to_sym )

      # Starting point
      best_so_far = Hash[ 'v' => normalize_version('0.0.0'), 'info' => Hash[ 'src' => false ]  ]

      case dependency_operator

      # Needs to be > version, and less than next major version
      when '~>'
        manifest[ cookbook.to_sym ].keys.each do |version|

          # depending on whether there are 2 or 3, only bump minor
          #   next major version
          digits = required_version.to_s.split('.').length
          if digits == 3
            next_version = required_version.bump(:minor)
          elsif digits == 2
            next_version = required_version.bump(:major)
          end

          # get a version object from the version at hand.
          candidate_version = normalize_version( version.to_s )

          # puts "#{candidate_version.to_s}  #{next_version.to_s} #{(candidate_version >= required_version)} #{candidate_version < next_version} #{(candidate_version > best_so_far['v'])}"

          if (candidate_version >= required_version) && (candidate_version < next_version) && (candidate_version > best_so_far['v'])
            best_so_far = Hash[ 'v' => candidate_version, 'info' => manifest[ cookbook.to_sym ][ version.to_sym ] ]
          end

        end

      when '>='
        manifest[ cookbook.to_sym ].keys.each do |version|

          # get a version object from the version at hand.
          candidate_version = normalize_version( version.to_s )

          if (candidate_version >= required_version) && (candidate_version > best_so_far['v'])
            best_so_far = Hash[ 'v' => candidate_version, 'info' => manifest[ cookbook.to_sym ][ version.to_sym ] ]
          end

        end

      when '='
        manifest[ cookbook.to_sym ].keys.each do |version|

          # get a version object from the version at hand.
          candidate_version = normalize_version( version.to_s )

          if (candidate_version == required_version)
            best_so_far = Hash[ 'v' => candidate_version, 'info' => manifest[ cookbook.to_sym ][ version.to_sym ] ]
          end

        end

        if best_so_far.to_s == '0.0.0'
          abort("Can't find a requirement")
        end

      end

    end

    tag = manifest[ cookbook.to_sym ][ best_so_far.to_s.to_sym ]

    path = File.join( CHEF_COOKBOOKS_DIR, cookbook )

    if best_so_far['info']['src'] == 'tag'
      system("cd #{path}; git checkout #{best_so_far['info']['name']} > /dev/null 2>&1;")
    elsif best_so_far['info']['src'] == 'master'
      system("cd #{path}; git checkout master > /dev/null 2>&1 && git fetch;")
    end

    system("knife cookbook upload #{cookbook}")

    # Reset
    system("cd #{path}; git checkout master > /dev/null 2>&1 && git fetch;")

  end # dependencies.each

  system("knife cookbook upload #{repo['name']}")

end
