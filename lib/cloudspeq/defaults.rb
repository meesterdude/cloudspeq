DEFAULT_SETTINGS = {
  'provider_key' => :digital_ocean,
  'spec_path' => 'spec',
  'file_pattern' => '_spec.rb(:\d+)?\z',
  'spec_line_pattern' => '/^(\s)+it|scenario/',
  'server_threads' => 1,
  'load_balance' => true,
  'digital_ocean' => {
    'machine_file' => 'cloudspeq_machines.yml'
  }
}