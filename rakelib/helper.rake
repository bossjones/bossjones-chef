#!/usr/bin/env rake

namespace :helper do

  desc "Apply shell command to all cookbooks in Repos.yml"
  task :shell, :command do |t, args|
    command = args[:command]

    repos = YAML::load( File.open('Repos.yml') )
    repos.each do |repo|

      puts "\n\nRunning command for #{repo['name']}:"
      Dir.chdir(File.join(CHEF_COOKBOOKS_DIR, repo['name']))

      sh command if command

    end
  end

end
