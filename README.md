# Kashi

Kashi is a tool to manage StatusCake. It defines the state of StatusCake using DSL, and updates StatusCake according to DSL.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kashi'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kashi

## Usage

```
export KASHI_SC_USER='...'
export KASHI_SC_API_KEY='...'
kashi -e # export StatusCake
vi SCfile
kashi -a --dry-run
kashi -a # apply `SCfile` to StatusCake
```

## Help

```
Usage: kashi [options]
    -h, --help                       Show help
    -a, --apply                      Apply DSL
    -e, --export                     Export to DSL
    -n, --dry-run                    Dry run
        --no-color
                                     No color
        --secret-provider NAME
                                     use secret value expansion
    -s, --split                      Split export DLS file contact group and tests
        --split-more
                                     Split export DLS file to 1 per object
    -v, --debug                      Show debug log
    -i, --include-names NAMES        include website_name
    -x, --exclude-names NAMES        exclude website_name by regex
```

## SCfile

See Accepted values at documents below.

- Contact Groups
  - https://www.statuscake.com/api/Contact%20Groups/Add%20or%20Update%20Contact%20Group.md
- Tests
  - https://www.statuscake.com/api/Tests/Updating%20Inserting%20and%20Deleting%20Tests.md

```ruby
cake do
  contact_group do
    group_name "Alarm"
    desktop_alert 0
    email ["wata.gm@gmail.com"]
    boxcar ""
    pushover ""
    ping_url ""
    mobile nil
  end

  test do
    paused 0

    test_type "HTTP"

    # Required Details
    website_name "your awesome site"
    website_url "https://example.com/healthcheck"

    contact_group ["Alarm"]

    # Scans
    enable_ssl_warning 1

    # HTTP Communication Options
    find_string ""
    do_not_find 0
    follow_redirect 1
    custom_header(
      {"Host"=>"example.com"}
    )
    status_codes ["204", "205", "206", "303", "400", "401", "403", "404", "405", "406", "408", "410", "413", "444", "429", "494", "495", "496", "499", "500", "501", "502", "503", "504", "505", "506", "507", "508", "509", "510", "511", "521", "522", "523", "524", "520", "598", "599", "302"]

    logo_image ""

    # Test Locations
    node_locations ["freeserver11"]

    # Threshold Control
    trigger_rate "0"
    confirmation "2"

    # Additional Options
    check_rate 300
    timeout 40
    test_tags ["Web", "Internal"]
    website_host ""
  end
end
```

## Secret provider

If you don't want to commit your Basic authentication password, you can use SecretProvider.
Use --secret-provider option to select provider.(e.g. --secret-provider=vault) Expression inside ${...} is passed to provider.

```ruby
  basic_user "username"
  basic_pass "${password}"
```

## Similar tools

* [Codenize.tools](http://codenize.tools/)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wata-gh/kashi.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
