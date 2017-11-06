module Kashi
  module Filterable
    def target?(website_name)
      unless @options[:includes].empty?
        unless @options[:includes].include?(website_name)
          Kashi.logger.debug("skip website_name(with include-names option) #{website_name}")
          return false
        end
      end

      unless @options[:excludes].empty?
        if @options[:excludes].any? { |regex| website_name =~ regex }
          Kashi.logger.debug("skip website_name(with exclude-names option) #{website_name}")
          return false
        end
      end
      true
    end
  end
end
