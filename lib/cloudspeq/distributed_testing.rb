require 'find'

class Cloudspeq
  class DistributedTesting
    

    def self.perform(settings,machines)
      @settings = settings
      @machines = machines.shuffle
      @threads      = []
      @outputs      = []
      @proccessed   = []
      @code_returns = []
      time = Benchmark.measure do
        test_clusters
        test_remaining
        @threads.each(&:join) 
      end

      {'time' => time.real, 'outputs' => @outputs}
    end

    private


    def self.test_clusters
      if @settings.clusters
        specified_servers = @settings.clusters.reject{|k,v| k == 'misc'}
        if specified_servers.empty?
          specified_servers = @machines.count
        else
          specified_servers = specified_servers.collect{|k,v| v['servers']}.inject(:+) + 1
        end
        if specified_servers  > @machines.count
          puts "ERROR: not enough servers. #{@machines.count} available, but #{specified_servers} needed"
          return false
        end
        @settings.clusters.each do |k,v|
          next if k == 'misc'
          specs = parse_specs(k,v) - @proccessed
          @proccessed.concat specs
          issue_specs(specs.shuffle,v)
        end
      end
    end

    def self.test_remaining
      remaining = parse_specs - @proccessed
      if @settings.clusters && @settings.clusters['misc']
        options = {'servers' => @machines.count, 'load_balance' => false, 'symbol' => '.'}.merge @settings.clusters['misc']
      else
        options = {'servers' => @machines.count, 'load_balance' => false}
      end
      issue_specs(remaining.shuffle, options)
    end


    # takes either a "valid" spec file, or directory. 
    def self.parse_specs(path="",v={})
      file_lines = []
      if path.match(@settings.file_pattern)
        proccess_lines(path,v)
      else
        Find.find("#{@settings.spec_path}/#{path}") do |file|
          lines = proccess_lines(file,v)
          next if lines.nil?
          file_lines.concat lines
        end
        file_lines
      end
    end

    def self.proccess_lines(file, v)
      if v['load_balance'] && (v['load_balance'] == false)
        return [file] 
      elsif  @settings.load_balance == false
        return [file]
      end
      if file.match(eval @settings.file_pattern)
        lines = `awk '#{@settings.spec_line_pattern}{print NR}' #{file}`.split("\n")
        return [] if lines.empty?
        lines.collect do |line|
          "#{file}:#{line}"
        end
      end 
    end

    def self.issue_specs(specs,v={'servers'=> 1})
      threads = v['threads'].nil? ? @settings.server_threads : v['threads']
      servers = v['servers'].nil? ? @machines.count : v['servers']
      per = v['per'].nil?  ? specs.count / [v['servers'].to_i,1].max / threads : v['per']
      per = per.ceil
      puts "#{v['symbol'] || '.'} - #{specs.count} specs on #{servers} servers with #{per} specs per connection and #{threads} connections per server"
      servers.times do
        machine = @machines.pop # take a machine from the pool
        threads.times do
          @threads << create_thread(machine,specs,per,v)
        end
      end
    end

    def self.create_thread(machine,specs,per,v)
      Thread.new do
        files = []
        while !specs.empty?
          spec_lines = []
          per.times{spec_lines << specs.pop}
          output = nil
          time = Benchmark.measure do
            output = machine.exec("bundle exec bin/rspec -f j #{spec_lines.join(" ")}", @settings)
          end
          host_report = {"output" => (JSON.parse(output) rescue output), 
                         "hostname" => machine.name, 
                         "ip_address" => machine.ip_address, 
                         "time" => time.real, 
                         "specs" => spec_lines, 
                         "symbol" => v['symbol']
                       }
          @outputs << host_report
          print type_return = v['symbol'] || '.'
          @code_returns << type_return
        end
      end
    end


  end
end