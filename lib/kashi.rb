require 'logger'
require 'kashi/version'
require 'kashi/ext/string-ext'

module Kashi
  def self.logger
    @logger ||=
      begin
        $stdout.sync = true
        Logger.new($stdout).tap do |l|
          l.level = Logger::INFO
        end
      end
  end
end
