require 'ostruct'
require 'kashi/dsl/test'
require 'kashi/dsl/contact_group'

module Kashi
  class DSL
    class Cake
      attr_reader :result

      def initialize(context, tests = [], contacts = [], &block)
        @context = context

        @result = OpenStruct.new(tests: tests, contact_groups: contacts)

        @tests = []
        @contacts = []
        instance_eval(&block)
      end

      private

      def test(*args, &block)
        test_id = nil
        unless args.empty?
          if @tests.include?(test_id)
            raise "#{test_id} is already defined"
          end
          test_id = args.first
        end

        @result.tests << Test.new(@context, test_id, &block).result
        @tests << test_id
      end

      def contact_group(*args, &block)
        contact_id = nil
        unless args.empty?
          if @contacts.include?(contact_id)
            raise "#{contact_id} is already defined"
          end
          contact_id = args.first
        end

        @result.contact_groups << ContactGroup.new(@context, contact_id, &block).result
        @contacts << contact_id
      end
    end
  end
end
