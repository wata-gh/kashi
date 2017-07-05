require 'ostruct'
require 'hashie'
require 'kashi/dsl/cake'

module Kashi
  class DSL
    class << self
      def define(source, filepath, options)
        self.new(filepath, options) do
          eval(source, binding, filepath)
        end
      end
    end

    attr_reader :result

    def initialize(filepath, options, &block)
      @filepath = filepath
      @result = OpenStruct.new(cake: nil)

      @context = Hashie::Mash.new(
        filepath: filepath,
        templates: {},
        options: options,
      )

      instance_eval(&block)
    end

    def require(file)
      scfile = (file =~ %r|\A/|) ? file : File.expand_path(File.join(File.dirname(@filepath), file))

      if File.exist?(scfile)
        instance_eval(File.read(scfile), scfile)
      elsif File.exist?("#{scfile}.rb")
        instance_eval(File.read("#{scfile}.rb"), "#{scfile}.rb")
      else
        Kernel.require(file)
      end
    end

    def template(name, &block)
      @context.templates[name.to_s] = block
    end

    def cake(&block)
      if @result.cake
        @result.cake = Cake.new(@context, @result.cake.tests, @result.cake.contact_groups, &block).result
      else
        @result.cake = Cake.new(@context, &block).result
      end
    end
  end
end
