class Cloudspeq
  class RspecOutputter

    def self.color(color, text)
      colors = {red: "0;31", 
                blue: '0;34', 
                green: '0;32', 
                yellow: '1;33', 
                light_green: '1;32', 
                light_red:'1;31', 
                light_blue: '1;34',
                purple: '0;35',
                light_purple: '1;35'
              }
    "\033[#{colors[color]}m #{text} \033[0m"
    end


    def self.perform(outputs)
      puts "\n\n ***** Spec Report *****\n\n"
      @failures = []
      @outputs = outputs['outputs']
      output_summary_lines
      output_failures
      puts "Total Time: #{outputs['time']}"
    end

    private

    def self.output_summary_lines
      @outputs.each do |o| 
        puts "#{o['symbol'] || '.'} - #{o['hostname']}: #{o['time'].to_s}  #{o['output']['summary_line'] rescue 'unexpected output'}" 
      end
    end

    def self.collect_failures
      @outputs.each do |o|
        if o['output']['examples']
          fails = o['output']['examples'].select{|t| t['status'] == 'failed'}
          fails.each do |f|
            @failures << "#{o['symbol'] || '.'} - #{o['hostname']}: #{f['file_path']}:#{f['line_number']} #{f['exception']['message']}"
          end
        end
      end
    end

    def self.output_failures
      collect_failures
      if !@failures.empty?
        puts "\n\nFailures:"
        @failures.each{|f| puts color(:red, f)}
        puts "Total Failures: #{@failures.size.to_s}"
      else
        puts color(:green, "No Failures!")
      end
    end

  end
end