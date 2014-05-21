#!/usr/bin/env rake

#######################################################################
# Behance Repo Tasks
#
namespace :repo do

  desc "Run git status on all cookbooks."
  task :status, :filter_input do |t, args|
    filter_input = args[:filter_input] || 'all'

    repos = YAML::load( File.open('Repos.yml') )

    puts "*** chef"
    system("git status;")

    repos.each do |repo|

      if filter(filter_input, repo) then

        Dir.chdir "#{CHEF_COOKBOOKS_DIR}/#{repo['name']}"

        status = `git status;`

        if ! status.include? "nothing to commit" then
          puts
          puts "*** #{repo['name']}"
          system("git status")
        end

      end

    end

  end

  # TODO: make this print columns
  desc "See what branches you're on."
  task :branch, :filter_input do |t, args|
    filter_input = args[:filter_input] || 'all'

    repos = YAML::load( File.open('Repos.yml') )

    puts "*** chef"
    system("git status;")

    repos.each do |repo|

      if filter(filter_input, repo) then

          Dir.chdir "#{CHEF_COOKBOOKS_DIR}/#{repo['name']}"
          branch = `git status | grep 'On branch' | awk '{ print $4 }';`.strip()

          if branch != 'master' then
            printf "*** %-25s %s\n", repo['name'], branch
          end


      end

    end

  end

  desc "Sync new cookbooks, update existing ones. Takes branch param if you're working on branches"
  task :update, :filter_input, :branch do |t, args|
    filter_input = args[:filter_input] || 'all'
    branch = args[:branch] || BUILD_BRANCH

    # Update the top-level chef repo
    puts "*** chef"
    system("cd #{TOPDIR}; git checkout #{branch}; git fetch; git pull --rebase origin #{branch};")

    # This will update all builtins
    Rake::Task[ "repo:update_builtins" ].invoke("all",branch)

    repos = YAML::load( File.open('Repos.yml') )

    repos.each do |repo|

      if filter(filter_input, repo) then

        puts "*** #{repo['name']}"

        path = File.join( CHEF_COOKBOOKS_DIR, repo['name'] )

        # Check the folder exists, if no, check it out
        if !File.directory?(path)
          FileUtils.mkdir_p(path)
          system("cd #{CHEF_COOKBOOKS_DIR}; git clone #{repo['url']};")
          system("cd #{CHEF_COOKBOOKS_DIR}/#{repo['name']}; git checkout #{branch}; git fetch; git pull --rebase origin #{branch};")
        else
          current_branch = `cd #{path}; git rev-parse --abbrev-ref HEAD`.strip

          puts "*** Current branch: #{current_branch}"

          # Check that the requested branch exists
          `cd #{path}; git show-ref --verify --quiet refs/heads/#{branch};`
          branch_exists = $?.exitstatus

          puts "*** Requested Branch: #{branch}"

          if branch_exists == 0 then
            puts "*** Pulling #{branch}"
            system("cd #{path}; git checkout #{branch};")
            system("cd #{path}; git fetch;")
            system("cd #{path}; git pull --rebase origin #{branch}; ")
          else
            system("cd #{path}; git fetch;")
            system("cd #{path}; git pull --rebase origin #{current_branch}; ")
          end


          if current_branch != branch && branch_exists == 0 then
            system("cd #{path}; git checkout #{current_branch};")
          end


        end

      end # inclusion

    end # repos.each

  end

  desc "Sync new cookbooks, update existing ones. Takes branch param if you're working on branches"
  task :update_sims do

    puts "*** sims"

    CHEF_SIMS_DIR = File.join(TOPDIR, 'sims')
    if !File.directory?(CHEF_SIMS_DIR)
      FileUtils.mkdir_p(CHEF_SIMS_DIR)
    end

    sims = YAML::load( File.open('Sims.yml') )

    sims.each do |sim|

      puts "*** #{sim['name']}"

      path = File.join( CHEF_SIMS_DIR, sim['name'] )

      # Check the folder exists, if no, check it out
      if !File.directory?(path)
        FileUtils.mkdir_p(path)
        system("cd #{CHEF_SIMS_DIR}; git clone #{sim['url']};")
      else
        current_branch = `cd #{path}; git rev-parse --abbrev-ref HEAD`.strip

        puts "*** Current branch: #{current_branch}"

        system("cd #{path}; git fetch; git pull --rebase origin #{current_branch}; ")
      end

    end # sims.each

  end

  desc "Sync new environments, roles, and data_bags. Takes branch param if you're working on branches"
  task :update_builtins, :filter_input, :branch do |t, args|
    filter_input = args[:filter_input] || 'all'
    branch = args[:branch] || BUILD_BRANCH

    CHEF_COOKBOOKS_DIR = File.join(TOPDIR, 'cookbooks')
    if !File.directory?(CHEF_COOKBOOKS_DIR)
      puts "Directory didn't exist. Making: #{ CHEF_COOKBOOKS_DIR }"
      FileUtils.mkdir_p(CHEF_COOKBOOKS_DIR)
    end

    if filter_input == 'all'
      update_git_repo("environments",branch)
      update_git_repo("roles",branch)
      update_git_repo("data_bags",branch)
    else
      update_git_repo(filter_input,branch)
    end

  end # task :update_environments

  desc "Build the Manifest"
  task :manifest_build do

    puts '*** BUILDING MANIFEST'

    manifile = 'Manifest.yml'

    if !File.exists?(manifile)
      `touch #{manifile}`
    end

    repos = YAML::load( File.open('Repos.yml') )

    manifest = YAML::load_file( manifile ) #Load

    if !manifest
      manifest = Hash.new
    end

    repos.each do |repo|

      puts "*** #{repo['name']}"

      manifest[ repo['name'].to_sym ] = Hash.new

      path = File.join( CHEF_COOKBOOKS_DIR, repo['name'] )

      # Put everything on master
      # Maybe, optionally, do a pull
      system("cd #{path}; git checkout master > /dev/null 2>&1 ;")

      tags = open("|cd #{path}; git tag;").read()

      tags.split( "\n" ).each do |tag|

        version = normalize_version( tag )

        manifest[ repo['name'].to_sym ][ version.to_s.to_sym ] =
                              Hash[ 'name' => tag, 'src' => 'tag']

      end

      metadata_file = File.join( path, 'metadata.rb' )

      if !File.exists?(metadata_file) then
        next
      end

      # Grab the version from the metadata
      metadata = Chef::Cookbook::Metadata.new
      metadata.from_file( File.join( path, 'metadata.rb' ) )

      version_symbol = normalize_version(metadata.version).to_s.to_sym

      manifest[ repo['name'].to_sym ][ version_symbol ] = Hash[ 'name' => metadata.version, 'src' => 'master' ]

    end

    File.open( manifile, "w") do |file|
      file.write manifest.to_yaml
    end

  end

  desc "Run bundle install on a cookbook"
  task :bundle_install, :filter_input do |t, args|
    filter_input = args[:filter_input]

    repos = YAML::load( File.open('Repos.yml') )

    repos.each do |repo|

      if filter(filter_input, repo) then

        puts "*** #{repo['name']}"

        path = File.join( CHEF_COOKBOOKS_DIR, repo['name'] )
        system("cd #{path}; bundle install;")

      end

    end

  end

end

def update_git_repo(built_in,branch = master)

    # defines all valid built_ins
    built_ins = %w{ environments roles data_bags }

    if built_ins.include? built_in
      # Update the roles repo.
      puts "*** #{built_in}"

      built_in_repo = "git@github.com:bossjones/bossjones-chef-#{built_in}.git"
      built_in_path = File.join( TOPDIR, "#{built_in}" )

      if !File.directory?( built_in_path ) then
        system("cd #{TOPDIR}; git clone #{built_in_repo} #{built_in_path}")
      else
        system("cd #{built_in_path}; git checkout #{branch}; git fetch; git pull --rebase origin #{branch};")
      end

    end # if built_ins.include

end # update_git_repo
