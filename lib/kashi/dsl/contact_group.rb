require 'colorize'
require 'kashi/utils'
require 'kashi/client_wrapper'

module Kashi
  class DSL
    class ContactGroup
      attr_reader :result

      class Result
        PARAMS = %i/ContactID GroupName DesktopAlert Email Boxcar Pushover PingURL Mobile/
        ATTRIBUTES = %i/contact_id group_name desktop_alert email boxcar pushover ping_url mobile/
        attr_accessor *ATTRIBUTES

        def initialize(context)
          @context = context
          @options = context.options
        end

        def to_h
          Hash[ATTRIBUTES.sort.map { |name| [name, public_send(name)] }]
        end

        def create_params
          hash = modify_params
          hash.delete(:ContactID)
          hash
        end

        def modify_params
          hash = to_h.select { |k, _| ATTRIBUTES.include?(k) }
          ATTRIBUTES.zip(PARAMS).each do |from, to|
            hash[to] = hash.delete(from)
          end
          hash[:Email] = Array(hash[:Email]).join(',')
          hash
        end

        def create
          Kashi.logger.info("Create ContactGroup `#{group_name}`".colorize(:green))
          Kashi.logger.debug(create_params)
          return { 'Success' => true } if @options[:dry_run]

          client.contactgroups_update(create_params)
        end

        def cake(sc_contact_group)
          @sc_contact_group = sc_contact_group
          self.contact_id = sc_contact_group['ContactID']
          self
        end

        def dsl_hash
          Kashi::Utils.normalize_hash(to_h)
        end

        def sc_hash
          hash = @sc_contact_group.to_h.keys.each_with_object({}) do |k, h|
            h[k.to_s.to_snake.to_sym] = @sc_contact_group.to_h[k]
          end
          { emails: :email, mobiles: :mobile }.each do |k, v|
            hash[v] = hash.delete(k)
          end
          Kashi::Utils.normalize_hash(hash)
        end

        def updated?
          dsl_hash != sc_hash
        end

        def modify
          return unless updated?
          Kashi.logger.info("Modify ContactGroup `#{group_name}` #{contact_id}".colorize(:blue))
          Kashi.logger.info("<diff>\n#{Kashi::Utils.diff(sc_hash, dsl_hash, color: @options[:color])}")
          Kashi.logger.debug(modify_params)
          return if @options[:dry_run]

          client.contactgroups_update(modify_params)
        end

        def client
          @client ||= ClientWrapper.new(@options)
        end
      end

      def initialize(context, contact_id, &block)
        @context = context.merge(contact_id: contact_id)

        @result = Result.new(@context)
        @result.contact_id = contact_id

        instance_eval(&block)
      end

      private

      def group_name(name)
        @result.group_name = name
      end

      def desktop_alert(alert)
        @result.desktop_alert = alert
      end

      def email(email)
        @result.email = Array(email)
      end

      def boxcar(boxcar)
        @result.boxcar = boxcar
      end

      def pushover(pushover)
        @result.pushover = pushover
      end

      def ping_url(url)
        @result.ping_url = url
      end

      def mobile(mobile)
        @result.mobile = mobile
      end
    end
  end
end
