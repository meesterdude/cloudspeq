class Cloudspeq
  class Providers
    class Base
      
      def initialize(settings)
        @settings = settings
      end
      
      def refresh
        @machines= remote_machines
        write_machines @machines
      end

      def machines
      end


      def sync
        machines.each do |machine|
          machine.sync(@settings)
        end
      end

      def sync
        threads = []
        output = {}
        machines.each do |m| 
          threads << Thread.new{ output[m.name] = m.sync(@settings) }
        end
        threads.each(&:join)
        output
      end

      # destroys machines and removes
      def destroy(machs)
        machs.each do |m|
          machines.delete m
          m.destroy
        end
      end

      def exec(command,machs=machines)
        threads = []
        output = {}
        machs.each do |m| 
          threads << Thread.new{ output[m.name] = m.exec(command,@settings) }
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

        def sync(settings)
          command = 'rsync -avz --delete -e "ssh -o StrictHostKeyChecking=no -x " '
          command += "--exclude='.git/' --exclude='log/' --exclude='tmp/' "
          settings.sync_excludes.each do |exc|
            command += "--include='#{exc}' "
          end
          command += ". #{settings.user}@#{attributes.ip_address}:#{settings.remote_project_directory}"
          `#{command}`
        end

        private

        def command_exec(user,ip_address,prefix,command)
          `ssh -o StrictHostKeyChecking=no -x -C #{user}@#{attributes.ip_address} "#{prefix} #{command}"`
        end

      end
    end
  end
end