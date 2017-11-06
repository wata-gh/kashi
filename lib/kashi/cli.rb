require 'optparse'
require 'kashi'

module Kashi
  class CLI
    def self.start(argv)
      new(argv).run
    end

    def initialize(argv)
      @argv = argv.dup
      @help = argv.empty?
      @filepath = 'SCfile'
      @options = {
        color: true,
        includes: [],
        excludes: [],
      }
      parser.order!(@argv)
    end

    def run
      if @help
        puts parser.help
      elsif @apply
        Apply.new(@filepath, @options).run
      elsif @export
        Export.new(@filepath, @options).run
      end
    end

    private

    def parser
      @parser ||= OptionParser.new do |opts|
        opts.version = VERSION
        opts.on('-h', '--help', 'Show help') { @help = true }
        opts.on('-a', '--apply', 'Apply DSL') { @apply = true }
        opts.on('-e', '--export', 'Export to DSL') { @export = true }
        opts.on('-n', '--dry-run', 'Dry run') { @options[:dry_run] = true }
        opts.on('',   '--no-color', 'No color') { @options[:color] = false }
        opts.on('',   '--secret-provider NAME', 'use secret value expansion') { |v| @options[:secret_provider] = v }
        opts.on('-s', '--split', 'Split export DLS file contact group and tests') { @options[:split] = true }
        opts.on('',   '--split-more', 'Split export DLS file to 1 per object') { @options[:split_more] = true }
        opts.on('-v', '--debug', 'Show debug log') { Kashi.logger.level = Logger::DEBUG }
        opts.on('-i', '--include-names NAMES', 'include website_name', Array) { |v| @options[:includes] = v }
        opts.on('-x', '--exclude-names NAMES', 'exclude website_name by regex', Array) do |v|
          @options[:excludes] = v.map! do |name|
            name =~ /\A\/(.*)\/\z/ ? Regexp.new($1) : Regexp.new("\A#{Regexp.escape(name)}\z")
          end
        end
      end
    end

    class Apply
      def initialize(filepath, options)
        @filepath = filepath
        @options = options
      end

      def run
        require 'kashi/client'
        result = Client.new(@filepath, @options).apply
      end
    end

    class Export
      def initialize(filepath, options)
        @filepath = filepath
        @options = options
      end

      def run
        require 'kashi/client'
        result = Client.new(@filepath, @options).export
      end
    end
  end
end
