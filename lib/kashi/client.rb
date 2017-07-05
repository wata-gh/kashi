require 'json'
require 'kashi'
require 'kashi/converter'
require 'kashi/client_wrapper'
require 'kashi/dsl'

module Kashi
  class Client
    MAGIC_COMMENT = <<-EOS
# -*- mode: ruby -*-
# vi: set ft=ruby :
    EOS

    def initialize(filepath, options = {})
      @filepath = filepath
      @options = options
    end

    def traverse_contact_groups(dsl_contact_groups, sc_contact_groups_by_id, sc_contact_groups_by_name)
      dsl_contact_groups_by_name = dsl_contact_groups.group_by(&:group_name).each_with_object({}) do |(k, v), h|
        h[k] = v.first
      end

      dsl_contact_groups_by_id = dsl_contact_groups.group_by(&:contact_id).each_with_object({}) do |(k, v), h|
        h[k] = v.first
      end

      # create
      dsl_contact_groups_by_name.reject { |n| sc_contact_groups_by_name[n] }.each do |name, dsl_contact_group|
        sc_contact_groups_by_name[name] = dsl_contact_group.create
      end

      # modify
      dsl_contact_groups_by_name.each do |name, dsl_contact_group|
        next unless sc_contact_group = sc_contact_groups_by_name.delete(name)

        dsl_contact_group.cake(sc_contact_group).modify
      end

      # delete
      sc_contact_groups_by_name.each do |name, sc_contact_group|
        Kashi.logger.info("Delete ContactGroup `#{name}`")
        next if @options[:dry_run]
        client.contactgroups_update(method: :delete, ContactID: sc_contact_group['ContactID'])
      end
    end

    def traverse_tests(dsl_tests, sc_tests_by_id, sc_tests_by_name)
      dsl_tests_by_name = dsl_tests.group_by(&:website_name).each_with_object({}) do |(k, v), h|
        h[k] = v.first
      end
      dsl_tests_by_id = dsl_tests.group_by(&:test_id).each_with_object({}) do |(k, v), h|
        h[k] = v.first
      end

      # create
      dsl_tests_by_name.reject { |n| sc_tests_by_name[n] }.each do |name, dsl_test|
        sc_tests_by_name[name] = dsl_test.create
      end

      # modify
      dsl_tests_by_name.each do |name, dsl_test|
        next unless sc_test = sc_tests_by_name.delete(name)

        sc_test = client.tests_details(TestID: sc_test['TestID'])
        dsl_test.cake(sc_test).modify
      end

      # delete
      sc_tests_by_name.each do |name, sc_test|
        Kashi.logger.info("Delete Test `#{name}`")
        next if @options[:dry_run]
        client.tests_details(method: :delete, TestID: sc_test['TestID'])
      end
    end

    def apply
      Kashi.logger.info("Applying...")
      dsl = load_file(@filepath)

      sc_contact_groups_by_id = client.contactgroups.each_with_object({}) do |contact_group, h|
        h[contact_group['ContactID']] = contact_group
      end
      sc_contact_groups_by_name = sc_contact_groups_by_id.each_with_object({}) do |(contact_id, contact_group), h|
        h[contact_group['GroupName']] = contact_group
      end

      sc_tests_by_id = client.tests.each_with_object({}) do |test, h|
        h[test['TestID']] = test
      end
      sc_tests_by_name = sc_tests_by_id.each_with_object({}) do |(test_id, test), h|
        h[test['WebsiteName']] = test
      end

      traverse_contact_groups(dsl.cake.contact_groups, sc_contact_groups_by_id, sc_contact_groups_by_name)

      traverse_tests(dsl.cake.tests, sc_tests_by_id, sc_tests_by_name)
    end

    def export
      Kashi.logger.info("Exporting...")

      # API access
      contact_groups = client.contactgroups(method: :get)
      contact_groups_by_id = contact_groups.each_with_object({}) do |contact_group, hash|
        hash[contact_group['ContactID']] = contact_group
      end

      # API access
      tests = client.tests(method: :get)
      tests_by_id = tests.each_with_object({}) do |test, hash|
        hash[test['TestID']] = cache(test['TestID']) do
          # API access
          client.tests_details(TestID: test['TestID'])
        end
      end

      path = Pathname.new(@filepath)
      base_dir = path.parent

      if @options[:split_more]
        # contact_groups
        contact_groups_by_id.each do |id, contact_group|
          Converter.new({}, { id => contact_group }).convert do |dsl|
            kashi_base_dir = base_dir.join('contact_groups')
            FileUtils.mkdir_p(kashi_base_dir)
            sc_file = kashi_base_dir.join("#{contact_group['GroupName'].gsub(/ /, '_')}.cake")
            Kashi.logger.info("Export #{sc_file}")
            open(sc_file, 'wb') do |f|
              f.puts MAGIC_COMMENT
              f.puts dsl
            end
          end
        end

        # tests
        tests_by_id.each do |id, test|
          Converter.new({ id => test }, {}).convert do |dsl|
            kashi_base_dir = base_dir.join('tests')
            FileUtils.mkdir_p(kashi_base_dir)
            sc_file = kashi_base_dir.join("#{test['WebsiteName'].gsub(/ /, '_')}.cake")
            Kashi.logger.info("Export #{sc_file}")
            open(sc_file, 'wb') do |f|
              f.puts MAGIC_COMMENT
              f.puts dsl
            end
          end
        end
      elsif @options[:split]
        # contact_groups
        Converter.new({}, contact_groups_by_id).convert do |dsl|
          sc_file = base_dir.join('contact_groups.cake')
          Kashi.logger.info("Export #{sc_file}")
          open(sc_file, 'wb') do |f|
            f.puts MAGIC_COMMENT
            f.puts dsl
          end
        end

        # test
        Converter.new(tests_by_id, {}).convert do |dsl|
          sc_file = base_dir.join('tests.cake')
          Kashi.logger.info("Export #{sc_file}")
          open(sc_file, 'wb') do |f|
            f.puts MAGIC_COMMENT
            f.puts dsl
          end
        end
      else
        FileUtils.mkdir_p(base_dir)
        Kashi.logger.info("Export #{path}")
        open(path, 'wb') do |f|
          f.puts MAGIC_COMMENT
          f.puts dsls.join("\n")
        end
      end
    end

    # for develop
    CACHE_DIR = Pathname.new("./tmp")
    def cache(key)
      cache_file = CACHE_DIR.join("#{key}.json")
      if cache_file.exist?
        return JSON.parse(cache_file.read)
      end

      yield.tap do |res|
        cache_file.write(res.to_json)
      end
    end

    def load_file(file)
      open(file) do |f|
        DSL.define(f.read, file, @options).result
      end
    end

    def client
      @client ||= ClientWrapper.new(@options)
    end
  end
end
