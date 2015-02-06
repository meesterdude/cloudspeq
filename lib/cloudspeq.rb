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

  def self.settings(path=nil)
    @settings ||= OpenStruct.new DEFAULT_SETTINGS.merge( YAML.load_file(path) )
  end

  def settings
    @settings
  end

  def status
    provider.status
  end

  def provider
    @provider
  end

  def spoolup(n=provider.provider_settings['machine_count'])
    provider.create n
  end

  def prepare
    output = []
    @settings['prepare'].each do |command|
     output << provider.exec(command)
    end
    output
  end

  def clean_up
    @settings['cleanup'].each do |command|
      provider.exec(command)
    end
  end

  def spool_down(n=provider.provider_settings['machine_count'])
    provider.destroy provider.machines.first(n)
  end

  def spool_down_all
    provider.spool_down_all
  end

  def sync
    provider.sync
  end

  # copies current ssh known_hosts to a backup
  def backup_ssh
    `cp ~/.ssh/known_hosts ~/.ssh/known_hosts.backup`
  end
  # restores known_hosts file, destroying backup
  def restore_ssh
    `mv ~/.ssh/known_hosts.backup ~/.ssh/known_hosts`
  end
  # restores known_hosts file, keeping backup
  def reset_ssh
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
