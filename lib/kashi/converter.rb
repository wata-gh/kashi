require 'erb'

module Kashi
  class Converter
    def initialize(tests_by_id, contact_groups_by_id)
      @tests_by_id = tests_by_id
      @contact_groups_by_id = contact_groups_by_id
    end

    def convert
      yield output_test(@tests_by_id, @contact_groups_by_id)
    end

    private

    def output_test(tests_by_id, contact_groups_by_id)
      path = Pathname.new(File.expand_path('../', __FILE__)).join('output_test.erb')
      ERB.new(path.read, nil, '-').result(binding)
    end
  end
end
