# CapybaraSpa

![https://travis-ci.org/mhs/capybara_spa.svg?branch=master](https://travis-ci.org/mhs/capybara_spa.svg?branch=master)

CapybaraSpa is a library to ease testing single page applications with Capybara.

Often, when developing an API server and a front-end client separately it can be a real pain to set up an integration testing environment.

## How does it work?

CapybaraSpa either runs (and terminates) an external processes for the front-end application, or, it will connect to an externally running process on a specified port. When the test suite boots up it will spawn a child process that server your front-end application.

It also updates Capybara's `visit` method to wait for the application to boot up before running the tests.. Then, when the test suite is done it will terminate any child processes.

Currently, you can:

* Run an inline static Angular 2, 4, 5, or 6 application using the `CapybaraSpa::Server::NgStaticServer`
* Connect to an external process running on a specified port using the `CapybaraSpa::Server::ExternalServer`

Coming soon you'll be able to:

* Run an inline external process by providing the command to start

## Installation

Add this line to the `test` group of application's Gemfile:

```ruby
gem 'capybara_spa', group :test
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capybara_spa

## Usage

You can use this with any Ruby testing library that Capybara works with.

### Require it in your test_helper, spec_helper, rails_helper, etc.

Here's a sample of using this library on a Rails project. Just update the `rails_helper.rb` after you Capybara is loaded. Then, create the server:

```ruby
require 'capybara/rails'
require 'capybara_spa'

FrontendServer = CapybaraSpa::Server::NgStaticServer.new(
  build_path: File.dirname(__FILE__) + '/../../public/app',
  http_server_bin_path: File.dirname(__FILE__) + '/../../node_modules/.bin/angular-http-server',
  log_file: File.dirname(__FILE__) + '/../../log/angular-process.log',
  pid_file: File.dirname(__FILE__) + '/../../tmp/angular-process.pid'
)
```

### Configure your test library to start and stop the server

Since we're using RSpec in this README, the next thing to do is configure RSpec to start and stop the server:

```ruby
RSpec.configure do |config|
  config.before(:each) do |example|
    if self.class.metadata[:js]
      begin
        FrontendServer.start unless FrontendServer.started?
      rescue CapybaraSpa::Server::Error => ex
        # Server raised an exception when starting. Force exit
        # so developer see the error immediately. Otherwise, RSpec/Capybara
        # are hanging around waiting for Puma to boot up.
        STDERR.puts ex.message, ex.backtrace.join("\n")
        exit!
      end
    end
  end

  config.after(:suite) do
    FrontendServer.stop if FrontendServer.started?
  end
end
```

### Starting and Stopping

Above, we added a `before(:each)` block to conditionally start the server. Since starting the server can be an expensive operation we only want to do it when we are running javascript specs (e.g. `:js`) and we only want to incur the cost once. So we essentially start it on the very first test that uses javascript and then we leave it running throughout of the test suite.

After that, an `after(:suite)` block is added to ensure that we stop the server. Technically, this is not necessary as  `CapybaraSpa` will install `at_exit` handlers to ensure that any child processes are terminated (to ensure no zombie processes creep up).

### Connecting to an external server

Let's say that you don't want to incur the startup cost of booting up the frontend server on every single test run. You can keep a frontend server running in a separate terminal tab and tell the test suite what port to connect to. For example, the above `CapybaraSpa::Server::NgStaticServer` could be replaced with the below lines:

```ruby
FrontendServer = CapybaraSpa::Server::ExternalServer.new(
  port: 5001 # port is the port that your front-end application server is running on
)
```

If you use the `CapybaraSpa::Server::ExternalServer` you will want to leave the `start` and `stop` configuration for your test library in place. This is so that you are notified of a failure if the external process/server is not running, not listening on the correct port, or does not stop.

By default, `CapybaraSpa::Server::ExternalServer` will wait up to 1 minute to attempt to connect to the port and it will wait up to 1 second for it to be stopped. You can change these values by passing in the `start_timeout` and `stop_timeout` options to the constructor.

### Why use a global constant?

The above example uses a global constant because it makes it accessible anywhere (e.g. say we're debugging a test and want to inspect the front-end server process) and because it essentially makes our server instance a singleton.

You can use a dollar-sign global (e.g. `$frontend_server`) or even a local variable (`frontend_server`). You can also name it whatever you like. Your call. Have fun.

### Configure Capybara

Here's a sample configuration of Capybara. It sets the `app_host` to be the front-end application that the browser will hit, and then it sets the back-end server to run on port 3001.

```ruby
Capybara.app_host = "http://localhost:#{FrontendServer.port}"
```

Next, be sure to tell Capybara to hit the backend server process on the right port, e.g.

```ruby
Capybara.server_port = 3001
```

This will require that your front-end application is also configured to connect to the backend on the same port.


### Configure the front-end app

For Angular 5 and 6 make a new environment (e.g. `ANGULAR_APP/src/environments/environment.integration.ts`) based off from an existing environment (either dev or production) but with the necessary API url configured to look for the API server on port 3001.

```javascript
export const environment = {
  production: false,
  apiUrl: 'http://localhost:3001'
};
```

Angular 6 requires one more change to. This time, a change to the `angular.json` configuration file. Be sure to add an integration `configuration`, e.g.:

```javascript
    "configurations": {
        "integration": {
            "fileReplacements": [
            {
                "replace": "src/environments/environment.ts",
                "with": "src/environments/environment.integration.ts"
            }
            ],
            "optimization": true,
            "outputHashing": "all",
            "sourceMap": false,
            "extractCss": true,
            "namedChunks": false,
            "aot": true,
            "extractLicenses": true,
            "vendorChunk": false,
            "buildOptimizer": true
        },
        // ....
    }
```

Now, you should be ready to go.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mhs/capybara_spa.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
