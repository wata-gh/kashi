require 'forwardable'
require 'statuscake'
require 'kashi/filterable'

module Kashi
  class ClientWrapper
    extend Forwardable
    include Filterable

    def_delegators :@client, *%i(
      contactgroups contactgroups_update
      tests_details tests_update
    )

    def initialize(options)
      @client = StatusCake::Client.new(API: ENV['KASHI_SC_API_KEY'], Username: ENV['KASHI_SC_USER'])
      @options = options
    end

    def tests
      @client.tests.select { |t| target?(t['WebsiteName']) }
    end
  end
end
