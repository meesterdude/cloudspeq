require 'ostruct'
require 'yaml'
require 'pry'
require 'benchmark'
require 'digitalocean'
require_relative "cloudspeq/version"
require_relative "cloudspeq/providers/base"
require_relative "cloudspeq/providers/digital_ocean"
require_relative "cloudspeq/defaults"
require_relative "cloudspeq/distributed_testing"
require_relative "cloudspeq/rspec_outputter"

class Cloudspeq
  # this is the public API. 

  def initialize(settings_path= 'cloudspeq.yml')
    @settings = Cloudspeq.settings(settings_path)
    provider_key = @settings['provider_key']
    provider = Object.const_get "Cloudspeq::Providers::" + provider_key.to_s.split("_").collect(&:capitalize).join
    
    @provider = provider.new(@settings)
  end

  def self.install
    File.open('cloudspeq.yml',"w") do |f|
      f.write(DEFAULT_SETTINGS.to_yaml)
    end
  end

  def self.settings(path=nil)
    @settings ||= OpenStruct.new DEFAULT_SETTINGS.merge( YAML.load_file(path) )
  end

  def settings
    @settings
  end

  def status
    refresh
    provider.status
  end

  def provider
    @provider
  end

  def spool_up(n=provider.provider_settings['machine_count'])
    provider.create n
  end

  def remote_prepare
    output = []
    @settings['remote_prepare'].each do |command|
     output << provider.exec(command)
    end
    output
  end

  def remote_clean_up
    @settings['remote_cleanup'].each do |command|
      provider.exec(command)
    end
  end

  def local_prepare
    output = []
    @settings['local_prepare'].each do |command|
     `#{command}`
    end
  end

  def local_clean_up
    @settings['local_clean_up'].each do |command|
      `#{command}`
    end
  end

  def spool_down(n=provider.provider_settings['machine_count'])
    provider.destroy provider.machines.first(n)
  end

  def spool_down_all
    provider.spool_down_all
  end

  def refresh
    provider.refresh
  end

  def sync
    provider.sync
  end

  def execute(cmd)
    provider.exec cmd
  end

  def root_execute(cmd)
    provider.root_exec cmd
  end

  # copies current ssh known_hosts to a backup
  def self.backup_ssh
    `cp ~/.ssh/known_hosts ~/.ssh/known_hosts.backup`
  end
  # restores known_hosts file, destroying backup
  def self.restore_ssh
    `mv ~/.ssh/known_hosts.backup ~/.ssh/known_hosts`
  end
  # restores known_hosts file, keeping backup
  def self.reset_ssh
    `cp ~/.ssh/known_hosts.backup ~/.ssh/known_hosts`
  end

  def run_tests(n=1) # run 1 time, by default
    output = []
    n.times do
      output << Cloudspeq::DistributedTesting.perform(@settings, provider.machines)
    end
    n == 1 ? output.first : output
  end

end
