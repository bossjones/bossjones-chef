#!/usr/bin/env rake

namespace :init do

  # TODO: check the cookbook actually exists
  desc "Set up cookbook for testing"
  task :test, :cookbook do |t, args|
    cookbook = args[:cookbook]

    unless cookbook
      abort("Please specify a cookbook")
    end

    boilerplate_folder = File.join(TOPDIR, %w(config boilerplate) )
    cookbook_folder = File.join(CHEF_COOKBOOKS_DIR, cookbook)

    top_level_files_to_overwrite = %w(.gitignore chefignore)
    top_level_files_to_create = %w(.kitchen.yml Berksfile)
    folders_to_create = %w(test/integration/helpers/serverspec tmp/cookbooks spec)

    top_level_files_to_overwrite.each do |file|
      puts "#{File.join(boilerplate_folder, file)} -> #{File.join(cookbook_folder, file)}"
      FileUtils.copy(File.join(boilerplate_folder, file), File.join(cookbook_folder, file) )
    end

    top_level_files_to_create.each do |file|
      unless File.exists?(File.join(cookbook_folder, file))
        puts "#{File.join(boilerplate_folder, file)} -> #{File.join(cookbook_folder, file)}"
        FileUtils.copy(File.join(boilerplate_folder, file), File.join(cookbook_folder, file) )
      end
    end

    folders_to_create.each do |folder|
      puts "Creating #{File.join(cookbook_folder, folder)}"
      FileUtils.mkdir_p File.join(cookbook_folder, folder)
    end

    # Additional files to copy over
    chefspec_location = 'spec/spec_helper.rb'
    serverspec_location = 'test/integration/helpers/serverspec/spec_helper.rb'
    unless File.exists?(File.join(cookbook_folder, chefspec_location))
      FileUtils.copy(File.join(boilerplate_folder, 'chef_spec_helper.rb'), File.join(cookbook_folder, chefspec_location) )
    end

    unless File.exists?(File.join(cookbook_folder, serverspec_location))
      FileUtils.copy(File.join(boilerplate_folder, 'server_spec_helper.rb'), File.join(cookbook_folder, serverspec_location) )
    end

    # set the git pre-commit hook
    git_hook(cookbook)

    #Add cookbook to Repos.yml
    exists = false
    YAML::load(File.open('Repos.yml')).each do |c|
      if c.has_value?(cookbook)
        exists = true
        next
      end
    end

    unless exists
      open(File.join(TOPDIR, "Repos.yml"), 'a') do |f|
        f.puts " -\n  name: #{cookbook}\n  tags:\n  url: \"git@github.com:behanceops/#{cookbook}.git\""
      end
    end
  end

  desc "Setup git pre-commit hook"
  task :set_commit_hook, :cookbook do |t, args|
    cookbook = args[:cookbook]

    unless cookbook
      abort("Please specify a cookbook")
    end

    git_hook(cookbook)
  end

  desc "Set git pre-commit hook for all cookbook repos"
  task :set_commit_hook_all do
    repos = YAML::load( File.open('Repos.yml') )
    repos.each do |repo|
      puts "setting pre-commit hook for #{repo['name']}"
      git_hook(repo["name"])
    end
  end

  desc "Set github webhook"
  task :set_webhook, :cookbook do |t, args|
    cookbook = args[:cookbook]

    unless cookbook
      abort("Please specify a cookbook")
    end

    webhook(cookbook)
  end

  desc "Set webhook for all cookbook repos"
  task :set_webhook_all do
    repos = YAML::load( File.open('Repos.yml') )
    repos.each do |repo|
      puts "setting webhook for #{repo['name']}"
      webhook(repo['name'])
    end
  end
end
