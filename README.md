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

```ruby
TBD
```

## Similar tools

* [Codenize.tools](http://codenize.tools/)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wata-gh/kashi.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
