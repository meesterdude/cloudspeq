# Cloudspeq (Beta)

Cloudspeq distributes your specs across machines in the cloud to dramatically reduce the time it takes to test. 

## Introduction

Fast specs are ideal in development, but are often not possible for an app due to cost or effort required, or simply because there are a lot of slow things to test. What is a developer to do, sit around while the tests run? Some test suits can take half an hour! 

To address this, cloudspeq throws computing power at it.

### Benefits

 - Plug and play: works with any rails codebase without app configuration
 - Fast: Can make a 5 minute test suit run in 20 seconds
 - Scalable: Can work with 10 machines, or 100. 
 - Controlable: You control what kind of machines to use, how many, and for how long. You also control which provider to use (so long as its digital ocean)
 - Load Balanced: specs are parsed for definitions and randomly distributed across machines to reduce testing hotspots
 - Clusters: Some directories / files / specs need special attention. Set aside machines to focus specifically on them
 - Safe: Ignores other machines on the provider that do not relate to testing
 - More Safe: Machines can self-destruct to ensure you dont get charged for machines you're not using

Right now, only Digital Ocean is supported as a provider, but others providers are possible in the future. 

Written to work with Rspec, but other test frameworks should more or less work too. 

### Cloudspeq Vs. CI

Cloudspeq was built to make testing in dev faster by working with the code you haven't commited to your repositiory. This is different from the role of CI, which is to test commited code, and where the test time is not as noticeable. This isn't to say Cloudspeq can't serve a CI role, only that it was not an orignal design intention. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cloudspeq'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cloudspeq


To install the require config file, execute:

```
cloudspeq install
```

The `cloudspeq.yml` file contains all the defaults that cloudspeq uses. You'll need to fill in the neccesary provider information. Everything but the provider info can be removed if you want to rely on the defaults; or you can customize them to suit your needs. 

## Preperation

You'll need a machine that can run your tests. This can be achieved by either:
  
  1. Creating a machine image
  2. Preparing the machine after boot

It is highly recommend you create a machine image to reduce the time it takes to prepare for testing. 

Things you'll need to do:
  1. Ensure user & project directory exist as defined in `cloudspeq.yml`
  2. Sync local directory to remote project directory (you can run `cloudspeq machines sync`). configure `sync_excludes` in the config file to skip any directories not needed for test; it already skips `.git/` and `tmp/`.
  3. Ensure test suite runs on remote machine
  4. Install ssh keys for root & user on remote machine
  5. Optionally, you can have the machines self-destruct after a certain ammount of uptime. This is a great way to ensure machines don't accidently linger for longer than they need to, in case you forget to delete the machines after testing. It also means if you want more time, you can just reboot. For this to work it requires cloudspeq be installed on the machine, and that it have access to the `cloudspeq.yml` file. Then you just need to define a cron entry for it. For example:

  ```
  */2 * * * * cd /home/tester/project/; /usr/local/bin/cloudspeq self_destruct
  ```

  Adjust to match your enviroment, and be sure to test it works in cron before relying on it. By default, the `server_lifetime` is 90 (minutes), but you can change this in the `cloudspeq.yml` file, or specify the number of minutes by passing it as a parameter to the `self_destruct` command. 
  6. Shutdown the machine, and create a snapshot
  7. In `cloudspeq.yml`, specify `image_name` using the name of the snapshot you just created under the provider



## Usage


### Create some machines to test with

 ```
 cloudspeq machines create
 ```

 This creates the number of machines specified in the provder machine_count. You can run this command multiple times to create machines in multiples, or provide the number to create as a parameter to the command. 


### Check the status of the machines

Creating machines can take a few minutes, especially if you create a lot. Run the status command to see how things are coming along

```
cloudspeq machines status
```

### Prepare SSH (recommended)

SSH-ing into the machines modifies `~/.ssh/known_hosts` but these entries can lead to warnings later if we create another machine with the same IP and a different public_key. So, this will backup the file for later restoration. 

```
cloudspeq ssh backup
```

### Sync 

Sync the project files to the machines

```
cloudspeq machines sync
```

### Prepare for testing

Executes all `remote_prepare` commands defined in the config file. Useful for starting up services, migrations, or what have you. 

```
cloudspeq machines prepare
```

### Run tests

Run the tests and get a report of the results. This will request a JSON formatted response from each machine, and parse each to gather failure and summary results. 

```
cloudspeq run
```

### Destroy

After testing, destroy the machines

```
cloudspeq machines destroy
```

This destroys the same number of machines defined in `machine_count`. You can also pass this command a number to specify how many machines to destroy. 

The above only pulls from the local machines file, and might not destroy all the machines. To destroy all machines on the provider that are test related:

```
cloudspeq machines destroy_all
```

Machines not related to testing, such as production machines, are ignored. 

### Restore SSH

```
cloudspeq ssh restore
```

### Additional Usage

 - You can use the `machines execute` and `machines root_execute` to execute commands across the machines
 - To run commands locally for prepare: `cloudspeq prepare` and for cleanup: `cloudspeq clean_up`

Most commands have a short-hand that is a few letters long. See `cloudspeq -h` for more info, or `cloudspeq command -h` for specific command related help. 

## Optimizations

While cloudspeq can dramtically speed things up out of the box, with some tuning you can get things running even faster. 

### Clusters

While Cloudspeq load-balancing can reduce hotspots, Sometimes you need to isolate the slow specs. By defining a cluster, you can dedicate machines to focus on something in particular, in order to reduce the overall time it takes for the test suite to execute. it can take some tinkering to identify an ideal configuation for your particular app. 

By default, all specs are distributed and run under a default cluster "misc", where misc has a machine pool equal to the number of machines defined. When you define a cluster, machines are set aside from those available, and the specs that are sent to them are removed from misc. The 'misc' group is the catch-all, and you'll get an error if there is not at least 1 machine available for it.

The order matters, so its best to be specific at the top and general at the bottom. 

an example clusters definition looks like:

```
clusters:
  "controllers/search_controller_spec.rb":  {servers: 2, symbol: 'G'}
  "controllers/store":                      {servers: 4, symbol: "S", threads: 2}
  "acceptance":                             {servers: 2, symbol: 'A', per: 1}
  "models":                                 {servers: 3, symbol: 'M', load_balance: false}
```

Each cluster consists of:
   
  1. a directory, file, or line number to test; as the key
  2. a hash value containing
    1. `servers` is to specify the number of machines to dedicate
    2. `symbol` is the symbol to use in output when representing (optional - defaults to '.')
    3. `load_balance` is to control if spec files should be broken up or fed in whole; useful if a spec file has expensive setup, but otherwise load_balancing is faster.
    4. `threads` controls the number of SSH connections to make to each machine, by default just 1. Useful if your tests can run in paralell without interfering with each other in the database, and you want to drive the machine harder.
    5. `per` defines how many specs each thread should receive. by default it is number of specs / number of threads, but if you specify a lower number it will cause machines to come back after finishing and be available for additional specs to work on, instead of sitting idle after they've finished. 

If you define a 'misc' cluster (with 'misc' as the key) as the last definition, you can adjust these parameters as they apply to any specs that fall in the misc group. This is also useful if you want to experiment with how long the specs take to run with a given number of machines. 

### Spec Tuning

To optimize your tests to run with cloudspeq, they should be fast. Load-balancing and clusters can help a lot, but in the end you'll only be able to be as fast as your slowest spec. If you have a spec that checks 6 different things and takes 6 seconds to run, you can optimize it by breaking it up into different specs, so that load-balancing can distribute the load across multiple machines.

## Roadmap

Cloudspeq is just getting started! Coming eventually:

- More providers (EC2, linode, raspberry-pi)
- Test coverage
- Better test profiling display
- Machine profiling
- Machine profiling test correlation
- Automatic tuning & optimizing
- Framework Atheism
- Distributed Rails Load Testing

Want to help realize one of these ideas, or have an idea of your own? Submit a PR! 

## Contributing

1. Fork it ( https://github.com/meesterdude/cloudspeq/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

MIT
