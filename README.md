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
    -s, --split                      Split export DLS file contact group and tests
        --split-more
                                     Split export DLS file to 1 per object
    -v, --debug                      Show debug log
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
    website_name "your awesome site"
    website_url "https://example.com/healthcheck"

    paused 0
    # HTTP,TCP,PING
    test_type "HTTP"
    contact_group ["Alarm"]
    check_rate 300
    timeout 40
    website_host ""
    node_locations ["freeserver2"]
    find_string ""
    do_not_find 0
    logo_image ""

    custom_header(
      {"Host"=>"example.com"}
    )
    confirmation "2"

    basic_user nil
    basic_pass nil

    use_jar nil

    dns_ip ""
    dns_server ""
    trigger_rate "0"
    test_tags ["Web", "Internal"]
    status_codes ["204", "205", "206", "303", "400", "401", "403", "404", "405", "406", "408", "410", "413", "444", "429", "494", "495", "496", "499", "500", "501", "502", "503", "504", "505", "506", "507", "508", "509", "510", "511", "521", "522", "523", "524", "520", "598", "599", "302"]
    enable_ssl_warning 0
    follow_redirect 1
  end
end
```

## Similar tools

* [Codenize.tools](http://codenize.tools/)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wata-gh/kashi.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
