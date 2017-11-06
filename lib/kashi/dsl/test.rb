require 'ostruct'
require 'kashi/secret_expander'

module Kashi
  class DSL
    class Test
      class Result
        PARAMS = %i/
          TestID Paused WebsiteName WebsiteURL Port NodeLocations Timeout CustomHeader Confirmation CheckRate
          DNSServer DNSIP BasicUser BasicPass LogoImage UseJar WebsiteHost Virus FindString DoNotFind
          TestType ContactGroup TriggerRate TestTags StatusCodes EnableSSLWarning FollowRedirect
          PostRaw FinalEndpoint
        / # PingURL RealBrowser Public Branding
        ATTRIBUTES = %i/
          test_id paused website_name website_url port node_locations timeout custom_header confirmation check_rate
          dns_server dns_ip basic_user basic_pass logo_image use_jar website_host virus find_string do_not_find
          test_type contact_group trigger_rate test_tags status_codes enable_ssl_warning follow_redirect
          post_raw final_endpoint
        / # ping_url real_browser public branding
        attr_accessor *ATTRIBUTES

        def initialize(context)
          @context = context
          @options = context.options
          @options[:secret_expander] = SecretExpander.new(@options[:secret_provider]) if @options[:secret_provider]
        end

        def to_h
          Hash[ATTRIBUTES.sort.map { |name| [name, public_send(name)] }]
        end

        def modify_params
          hash = to_h.select { |k, _| ATTRIBUTES.include?(k) }
          ATTRIBUTES.zip(PARAMS).each do |from, to|
            hash[to] = hash.delete(from)
          end
          %i/NodeLocations TestTags StatusCodes/.each do |k|
            hash[k] = Array(hash[k]).join(',')
          end
          contact_group_id_by_group_name = client.contactgroups.each_with_object({}) do |contact_group, h|
            h[contact_group['GroupName']] = contact_group['ContactID']
          end
          hash[:ContactGroup] = contact_group.map { |name|
            contact_group_id_by_group_name[name]
          }.compact.join(',')
          hash
        end

        def create_params
          hash = modify_params
          hash.delete(:TestID)
          hash
        end

        def create
          Kashi.logger.info("Create Test `#{website_name}`")
          Kashi.logger.debug(create_params)
          return { 'Success' => true } if @options[:dry_run]

          client.tests_update(create_params)
        end

        def cake(sc_test)
          @sc_test = sc_test
          self.test_id = sc_test['TestID']
          self
        end

        def dsl_hash
          Kashi::Utils.normalize_hash(to_h)
        end

        def sc_hash
          hash = @sc_test.to_h.keys.each_with_object({}) do |k, h|
            next if %w/DownTimes LastTested NextLocation Processing ProcessingOn ProcessingState Sensitive Status Uptime Method ContactGroup ContactID/.include?(k)
            h[k.to_s.to_snake.to_sym] = @sc_test.to_h[k]
          end
          # rename
          { uri: :website_url, dnsip: :dns_ip, tags: :test_tags }.each do |k, v|
            hash[v] = hash.delete(k)
          end
          %i/basic_user basic_pass/.each do |k|
            hash[k] = ''
          end
          %i/port use_jar virus/.each do |k|
            hash[k] = '' unless hash.key?(k)
          end
          %i/paused enable_ssl_warning follow_redirect do_not_find/.each do |k|
            hash[k] = hash[k] ? 1 : 0
          end
          hash[:contact_group] = hash.delete(:contact_groups).map { |contact_group| contact_group['Name'] }
          hash[:test_tags] = Array(hash[:test_tags])
          if hash[:custom_header] == false || hash[:custom_header] == ''
            hash[:custom_header] = ''
          else
            hash[:custom_header] = JSON.parse(hash[:custom_header]).to_json
          end
          Kashi::Utils.normalize_hash(hash)
        end

        def updated?
          dsl_hash != sc_hash
        end

        def modify
          return unless updated?
          Kashi.logger.info("Modify Test `#{website_name}` #{test_id}")
          masked_dsl_has = dsl_hash.dup.tap { |h| h[:basic_pass] = '****' }
          Kashi.logger.info("<diff>\n#{Kashi::Utils.diff(sc_hash, masked_dsl_has, color: @options[:color])}")
          Kashi.logger.debug(modify_params)
          return if @options[:dry_run]

          client.tests_update(modify_params)
        end

        def basic_pass
          secret_expander = @options[:secret_expander]
          if secret_expander
            secret_expander.expand(@basic_pass)
          else
            @basic_pass
          end
        end

        def client
          @client ||= ClientWrapper.new(@options)
        end
      end

      attr_reader :result

      def initialize(context, test_id, &block)
        @context = context.merge(test_id: test_id)

        @result = Result.new(@context)
        @result.test_id = test_id

        # default values
        @result.paused = 0
        @result.timeout = 30
        @result.confirmation = 0
        @result.check_rate = 300
        # @result.public = 0
        # @result.use_jar = 0
        # @result.branding = 0
        @result.do_not_find = 0
        # @result.real_browser = 0
        @result.trigger_rate = 5
        @result.enable_ssl_warning = 1
        @result.follow_redirect = 1
        @result.test_tags = []
        @result.node_locations = ['']
        @result.status_codes = []
        @result.virus = ''

        # not used
        @result.post_raw = ''
        @result.final_endpoint = ''

        instance_eval(&block)
      end

      private

      def paused(paused)
        @result.paused = paused
      end

      def website_url(url)
        @result.website_url = url
      end

      def website_name(name)
        @result.website_name = name
      end

      def port(port)
        @result.port = port
      end

      # def ping_url(url)
      #   @result.ping_url = url
      # end

      def custom_header(header)
        if header == '' || header == nil
          @result.custom_header = ''
        else
          @result.custom_header = header.to_json
        end
      end

      def confirmation(confirmation)
        @result.confirmation = confirmation
      end

      def test_type(type)
        @result.test_type = type
      end

      def contact_group(groups)
        @result.contact_group = Array(groups)
      end

      def check_rate(rate)
        @result.check_rate = rate
      end

      def timeout(timeout)
        @result.timeout = timeout
      end

      def website_host(host)
        @result.website_host = host
      end

      def node_locations(locations)
        @result.node_locations = locations
      end

      def find_string(str)
        @result.find_string = str
      end

      def do_not_find(do_not_find)
        @result.do_not_find = do_not_find
      end

      def basic_user(user)
        @result.basic_user = user
      end

      def basic_pass(pass)
        @result.basic_pass = pass
      end

      # def public(pub)
      #   @result.public = pub
      # end

      def logo_image(logo)
        @result.logo_image = logo
      end

      def use_jar(use_jar)
        @result.use_jar = use_jar
      end

      # def branding(branding)
      #   @result.branding = branding
      # end

      def virus(virus)
        @result.virus = virus
      end

      # def real_browser(real_browser)
      #   @result.real_browser = real_browser
      # end

      def dns_server(dns_server)
        @result.dns_server = dns_server
      end

      def dns_ip(ip)
        @result.dns_ip = ip
      end

      def trigger_rate(rate)
        @result.trigger_rate = rate
      end

      def test_tags(tags)
        if tags == nil
          @result.test_tags = []
        end
        @result.test_tags = Array(tags)
      end

      def status_codes(codes)
        @result.status_codes = codes
      end

      def enable_ssl_warning(enable_ssl_warning)
        @result.enable_ssl_warning = enable_ssl_warning
      end

      def follow_redirect(follow_redirect)
        @result.follow_redirect = follow_redirect
      end
    end
  end
end
