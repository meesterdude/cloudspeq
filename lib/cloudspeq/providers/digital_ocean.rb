class Cloudspeq
  class Providers
    class DigitalOcean < Base

      def initialize(settings)
        ::Digitalocean.client_id  = settings.digital_ocean['client_id']
        ::Digitalocean.api_key    = settings.digital_ocean['api_key']
        @settings =               settings
        @digital  =               settings.digital_ocean
        @machines =               machines
      end

      def provider_settings
        @digital
      end

      def create(count=@digital['machine_count'])
        created = []
        count.to_i.times do 
          response = Digitalocean::Droplet.create({name: generate_machine_name, 
                                                   size_id: size.id, 
                                                   image_id: image.id, 
                                                   region_id: region.id, 
                                                   ssh_key_ids: ssh_key.id})
          if response.status == "OK"
            created << response.droplet
          else
            puts response
          end
        end
        created.each do |machine|
          @machines << Machine.new(Digitalocean::Droplet.find(machine.id).droplet.to_h)
        end
      
      end

      def machines(file='cloudspeq_machines.yml')
        File.write(file, '') unless File.exist?(file)
        yaml = YAML.load_file(file)
        yaml =  [] if yaml == false
        yaml.class == Array ? yaml : [yaml]
      end

      # by default, only grab machines that look like they're related to testing
      # be careful if you set this to true and have other machines on your account
      def remote_machines(all=false)
        if all
         machines = ::Digitalocean::Droplet.all
        else
          string = @settings.machine_prefix ? "#{@settings.machine_prefix}-" : "test-"
          machines = ::Digitalocean::Droplet.all.droplets.select{|d| d.name.start_with?(string)}
        end
        machines.collect{|m| Machine.new(m)}
      end

      def write_machines(machs,file=@digital['machine_file'])
        @machines= machs
        File.open(file,"w") do |f|
          f.write(machs.to_yaml)
        end
        
      end

      def image
        ::Digitalocean::Image.all.images.select{|i| i.name == @digital['image_name']}.first
      end

      def ssh_key
        ::Digitalocean::SshKey.all.ssh_keys.select{|i| i.name == @digital['ssh_key_name']}.first
      end

      def size
        ::Digitalocean::Size.all.sizes.select{|s| s.slug == @digital['size_slug']}.first
      end

      def region
        ::Digitalocean::Region.all.regions.select{|r| r.slug == @digital['region_slug']}.first
      end

      def status
        status_hashes = machines.collect {|m| {"#{m.attributes.name}" => m.attributes.status} }
        statuses = status_hashes.collect{|m| m.values}.flatten
        new_machines = statuses.select{|m| m == 'new'}
        active_machines = statuses.select{|m| m == 'active'}
        {'total' => statuses.count, 'new' => new_machines.count, 'active' => active_machines.count, 'machines' => status_hashes}
      end

      def spool_down_all
        destroy remote_machines
      end




      class Machine < Base::Machine

        def name
          attributes.name
        end

        def ip_address
          attributes.ip_address
        end

        def power_off
          ::Digitalocean::Droplet.power_off(attributes.id)
        end

        def power_cycle
          ::Digitalocean::Droplet.power_cycle(attributes.id)
        end

        def power_on
          ::Digitalocean::Droplet.power_on(attributes.id)
        end

        def destroy
          ::Digitalocean::Droplet.destroy(attributes.id)
        end

      end
    end
  end
end

