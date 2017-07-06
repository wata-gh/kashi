require 'forwardable'
require 'statuscake'

module Kashi
  class ClientWrapper
    extend Forwardable

    def_delegators :@client, *%i/
      contactgroups contactgroups_update
      tests tests_details tests_update
    /

    def initialize(options)
      @client = StatusCake::Client.new(API: ENV['KASHI_SC_API_KEY'], Username: ENV['KASHI_SC_USER'])
    end
  end
end
