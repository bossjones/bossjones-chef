#!/usr/bin/env rake

require 'facter'

namespace :test do

  desc "Runs knife cookbook test"
  task :knife do
    change_to_cookbook_dir
    Rake::Task["test:prepare_sandbox"].execute

    sh "bundle exec knife cookbook test cookbook -o #{sandbox_path}/../"
  end

  desc "Runs rubocop test"
  task :rubocop do
    change_to_cookbook_dir
    rubocop_path = '../../.rubocop.yml'

    sh "bundle exec rubocop --format simple #{cookbook_dir}"
  end

  desc "Runs foodcritic linter"
  task :foodcritic do
    change_to_cookbook_dir
    if Gem::Version.new("1.9.2") <= Gem::Version.new(RUBY_VERSION.dup)
      Rake::Task["test:prepare_sandbox"].execute

      sh "foodcritic -f correctness -f metadata #{sandbox_path}"
    else
      puts "WARN: foodcritic run is skipped as Ruby #{RUBY_VERSION} is < 1.9.2."
    end
  end

  desc "Runs ChefSpec tests, if there are any"
  task :chefspec do
    change_to_cookbook_dir
    unless is_directory?('spec')
      puts "spec folder doesn't exist"
      next
    end

    # resolve dependencies via berkshelf
    sh "bundle exec berks install --berksfile #{cookbook_dir}/Berksfile"

    # run those tests
    sh "bundle exec rspec --color --format documentation --backtrace #{cookbook_dir}/spec"

  end

  desc "Runs Test Kitchen and ServerSpec tests"
  task :kitchen do
    change_to_cookbook_dir

    unless is_directory?('test/integration')
      puts "test/integration folder doesn't exist"
      next
    end

    case ENV['TEST_ENV']
    when 'jenkins'
      box = :jenkins
    else
      box = :local
    end

    # Find number of cpus on this machine
    Facter.loadfacts
    numcpus = Facter.processorcount.to_i

    sh "bundle exec kitchen test #{box} --destroy=always --concurrency=#{numcpus - 1} --destroy always"

  end

  desc "Checks cookbook version"
  task :version do
    change_to_cookbook_dir

    sh "bundle exec knife spork check #{cookbook} --fail"
  end

  desc "Moves files into a testable state for knife + foodcritic tests"
  task :prepare_sandbox do
    files = %w{*.md *.rb attributes definitions files libraries providers recipes resources templates}

    rm_rf sandbox_path
    mkdir_p sandbox_path
    cp_r Dir.glob("{#{files.join(',')}}"), sandbox_path
  end

  desc "Run all tests"
  task :all => [
    "test:knife",
    "test:rubocop",
    "test:foodcritic",
    #"test:version",
    "test:chefspec",
    "test:kitchen"
  ]

  desc "Run pre-commit tests"
  task :hook => [
    "test:knife",
    "test:rubocop",
    "test:foodcritic",
    "test:version"
  ]

end

private

def change_to_cookbook_dir
  Dir.chdir(cookbook_dir)
end

def cookbook_dir
  Rake.application.original_dir
end

def cookbook
  File.basename cookbook_dir
end

def is_file?(filename)
  File.file?(File.join(cookbook_dir, filename))
end

def is_directory?(filename)
  File.directory?(File.join(cookbook_dir, filename))
end

def sandbox_path
  File.join(cookbook_dir, %w(tmp cookbooks cookbook))
end

def vendor_path
  File.join(cookbook_dir, %w(.vendor cookbooks))
end
