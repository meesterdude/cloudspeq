class Cloudspeq
  class Providers
    class Base
      
      def initialize(settings)
        @settings = settings
      end
      
      def sync
        @machines= remote_machines
        write_machines @machines
      end

      # destroys machines and removes
      def destroy(machs)
        machs.each do |m|
          machines.delete m
          m.destroy
        end
      end

      def exec(command,machs=machines)
        threads, output = [],[]
        machs.each do |m| 
          threads << Thread.new{ output << m.exec(command,@settings) }
        end
        threads.each(&:join)
        output
      end

      def exec!(command,machs=machines)
        threads = []
        machs.collect{|m| threads << Thread.new{m.exec! command, @settings}}
        threads.each(&:join)
      end

      def root_exec(command,machs=machines)
        threads = []
        machs.collect{|m| threads << Thread.new{m.root_exec command}}
        threads.each(&:join)
      end

      
      def self.find(hostname: '', ip_address: '')
        return false if hostname.empty? && ip_address.empty?  
        if !ip_address.empty?
        else
        end
      end
      
      def self.destroy(count)
      end

        private

        def generate_machine_name(settings=@settings)
          characters = ("a".."z").to_a + ('0'..'9').to_a
          prefix = settings.machine_prefix ? "#{settings.machine_prefix}-" : "test-"
          name = prefix + settings.project_name + "-" + characters.sample(4).join
        end

    end
  end
end



class Cloudspeq
  class Providers
    class Base
      class Machine

        def initialize(machine)
          @attributes = RecursiveOpenStruct.new(machine)
        end

        def attributes
          @attributes
        end

        def shutdown
        end

        def restart
        end

        def startup
        end

        def destroy
        end
        
        # most of the time, execution requires prefixing
        def exec(command,settings)
          user = settings.user
          prefix = settings.command_prefix
          command_exec(user,attributes.ip_address,prefix,command)
        end

        # execute without prefixing
        def exec!(command,settings)
          user = settings.user
          prefix = settings.command_prefix
          command_exec(user,attributes.ip_address,"",command)
        end
        
        # exec as root
        def root_exec(command)
          command_exec('root',attributes.ip_address,"",command)
        end

        private

        def command_exec(user,ip_address,prefix,command)
          `ssh -o StrictHostKeyChecking=no -x -C #{user}@#{attributes.ip_address} "#{prefix} #{command}"`
        end

      end
    end
  end
end