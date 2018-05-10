# CapybaraSpa

![https://travis-ci.org/mhs/capybara_spa.svg?branch=master](https://travis-ci.org/mhs/capybara_spa.svg?branch=master)

CapybaraSpa is a library to ease testing single page applications with Capybara.

Often, when developing an API server and a front-end client separately it can be a real pain to set up an integration testing environment.

## How does it work?

CapybaraSpa runs (and terminate) external processes for the front-end application. When the test suite boots up it will spawn a child process that server your front-end application.

It also updates Capybara's `visit` method to wait for the application to boot up before running the tests.. Then, when the test suite is done it will terminate any child processes.

Currently, you can:

* Run an inline static Angular 2, 4, 5, or 6 application using the `CapybaraSpa::Server::NgStaticServer`

Coming soon you'll be able to:

* Connect to an existing process (e.g. run a server in a separate terminal then tell your test quite about it)
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

```
require 'capybara/rails'
require 'capybara_spa'

$angular_http_server = CapybaraSpa::Server::NgStaticServer.new(
  build_path: File.dirname(__FILE__) + '/../../public/app',
  http_server_bin_path: File.dirname(__FILE__) + '/../../node_modules/.bin/angular-http-server',
  log_file: File.dirname(__FILE__) + '/../../log/angular-process.log',
  pid_file: File.dirname(__FILE__) + '/../../tmp/angular-process.pid'
)
```

Next, configure RSpec to start the server when running `:js` specs:

```
RSpec.configure do |config|
  config.before(:each) do |example|
    if self.class.metadata[:js]
      begin
        $angular_http_server.start unless $angular_http_server.started?
      rescue CapybaraSpa::Server::Error => ex
        # Server raised an exception when starting. Force exit
        # so developer see the error immediately. Otherwise, Ruby
        # was hanging while waiting for Puma to boot up.
        STDERR.puts ex.message, ex.backtrace.join("\n")
        exit!
      end
    end
  end
end
```

### No explicit stop?

You may have noticed that there is no `stop` call registered above. This is because CapybaraSpa will register its own `at_exit` handler(s) to ensure that it kills any child processes that it spawns to help avoid the risk of child zombie processes.

If you want to explicitly stop the server you can add the following:

```
RSpec.configure do |config|
  config.after(:suite) do |example|
    $angular_http_server.stop if $angular_http_server.started?
  end
end
```

### Why use a global variable?

The above example uses one because it makes it easy to reference from the necessary before/after hooks which exist. You do not need to use a global.

### Configure Capybara

Here's a sample configuration of Capybara. It sets the `app_host` to be the front-end application that the browser will hit, and then it sets the back-end server to run on port 3001.

```
Capybara.app_host = "http://localhost:#{$angular_http_server.port}"
```

Next, be sure to tell Capybara to hit the backend server process on the right port, e.g.

```
Capybara.server_port = 3001
```

This will require that your front-end application is also configured to connect to the backend on the same port.


### Configure the front-end app

For Angular 5 and 6 make a new environment (e.g. `ANGULAR_APP/src/environments/environment.integration.ts`) based off from an existing environment (either dev or production) but with the necessary API url configured to look for the API server on port 3001.

```
export const environment = {
  production: false,
  apiUrl: 'http://localhost:3001'
};
```

Angular 6 requires one more change to. This time, a change to the `angular.json` configuration file. Be sure to add an integration `configuration`, e.g.:

```
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
