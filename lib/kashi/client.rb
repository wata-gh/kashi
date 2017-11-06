require 'json'
require 'kashi'
require 'kashi/converter'
require 'kashi/client_wrapper'
require 'kashi/dsl'
require 'kashi/filterable'

module Kashi
  class Client
    include Filterable
    MAGIC_COMMENT = <<-EOS
# -*- mode: ruby -*-
# vi: set ft=ruby :
    EOS

    def initialize(filepath, options = {})
      @filepath = filepath
      @options = options
      @options[:secret_expander] = SecretExpander.new(@options[:secret_provider]) if @options[:secret_provider]
    end

    def traverse_contact_groups(dsl_contact_groups, sc_contact_groups_by_id, sc_contact_groups_by_name)
      dsl_contact_groups_by_name = dsl_contact_groups.group_by(&:group_name)
      dsl_contact_groups_by_id = dsl_contact_groups.group_by(&:contact_id)

      # create
      dsl_contact_groups_by_name.reject { |n| sc_contact_groups_by_name[n] }.each do |name, dsl_contact_group|
        sc_contact_groups_by_name[name] = dsl_contact_group.map(&:create)
      end

      # modify
      dsl_contact_groups_by_name.each do |name, dsl_contact_groups|
        next unless sc_contact_groups = sc_contact_groups_by_name.delete(name)

        if dsl_contact_groups.length == 1 && sc_contact_groups.length == 1
          next if sc_contact_groups[0]['Success'] # created contact group
          dsl_contact_groups[0].cake(sc_contact_groups[0]).modify
        else
          dsl_contact_groups.each do |dsl_contact_group|
            sc_contact_group = sc_contact_groups.find { |sc_cg| sc_cg['ContactID'] == dsl_contact_group.contact_id }
            raise "contact_id must be set if same name contact group exist. `#{name}`" unless sc_contact_group
            dsl_contact_group.cake(sc_contact_group).modify
          end
        end
      end

      # delete
      sc_contact_groups_by_name.each do |name, sc_contact_groups|
        sc_contact_groups.each do |sc_contact_group|
          Kashi.logger.info("Delete ContactGroup `#{name}` #{sc_contact_group['ContactID']}")
          next if @options[:dry_run]
          client.contactgroups_update(method: :delete, ContactID: sc_contact_group['ContactID'])
        end
      end
    end

    def traverse_tests(dsl_tests, sc_tests_by_id, sc_tests_by_name)
      dsl_target_tests = dsl_tests.select { |t| target?(t.website_name) }
      dsl_tests_by_name = dsl_target_tests.group_by(&:website_name)
      dsl_tests_by_id = dsl_target_tests.group_by(&:test_id)

      # create
      dsl_tests_by_name.reject { |n, _| sc_tests_by_name[n] }.each do |name, dsl_tests|
        sc_tests_by_name[name] = dsl_tests.map do |dsl_test|
          # if test_id exist, its name might been changed
          if dsl_test.test_id
            sc_test = sc_tests_by_id[dsl_test.test_id]
            if sc_test
              sc_tests_by_name[sc_test['WebsiteName']].delete_if { |sc_test| sc_test['TestID'] == dsl_test.test_id }
              next sc_test
            end
            next
          end
          dsl_test.create
        end
      end

      # modify
      dsl_tests_by_name.each do |name, dsl_tests|
        next unless sc_tests = sc_tests_by_name.delete(name)

        if dsl_tests.length == 1 && sc_tests.length == 1
          next if sc_tests[0]['Success'] # created test
          sc_test = client.tests_details(TestID: sc_tests[0]['TestID'])
          dsl_tests[0].cake(sc_test).modify
        else
          dsl_tests.each do |dsl_test|
            sc_test = sc_tests.find { |sc_t| sc_t['TestID'] == dsl_test.test_id }
            raise "test_id must be set if same name test exist. `#{name}`" unless sc_test
            sc_test = client.tests_details(TestID: sc_test['TestID'])
            dsl_test.cake(sc_test).modify
          end
        end
      end

      # delete
      sc_tests_by_name.each do |name, sc_tests|
        sc_tests.each do |sc_test|
          Kashi.logger.info("Delete Test `#{name}` #{sc_test['TestID']}")
          next if @options[:dry_run]
          client.tests_details(method: :delete, TestID: sc_test['TestID'])
        end
      end
    end

    def apply
      Kashi.logger.info("Applying...")
      dsl = load_file(@filepath)

      sc_contact_groups = client.contactgroups
      sc_contact_groups_by_id = sc_contact_groups.each_with_object({}) do |contact_group, h|
        h[contact_group['ContactID']] = contact_group
      end
      sc_contact_groups_by_name = sc_contact_groups.group_by do |contact_group|
        contact_group['GroupName']
      end

      sc_tests = client.tests
      sc_tests_by_id = sc_tests.each_with_object({}) do |test, h|
        h[test['TestID']] = test
      end
      sc_tests_by_name = sc_tests.group_by do |sc_tests|
        sc_tests['WebsiteName']
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
        # API access
        hash[test['TestID']] = client.tests_details(TestID: test['TestID'])
      end

      path = Pathname.new(@filepath)
      base_dir = path.parent

      if @options[:split_more]
        # contact_groups
        contact_groups_by_id.each do |id, contact_group|
          Converter.new({}, { id => contact_group }).convert do |dsl|
            kashi_base_dir = base_dir.join('contact_groups')
            FileUtils.mkdir_p(kashi_base_dir)
            sc_file = kashi_base_dir.join("#{contact_group['GroupName'].gsub(/[\/ ]/, '_')}_#{contact_group['ContactID']}.cake")
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
            sc_file = kashi_base_dir.join("#{test['WebsiteName'].gsub(/[\/ ]/, '_')}_#{test['TestID']}.cake")
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
        Converter.new(tests_by_id, contact_groups_by_id).convert do |dsl|
          FileUtils.mkdir_p(base_dir)
          Kashi.logger.info("Export #{path}")
          open(path, 'wb') do |f|
            f.puts MAGIC_COMMENT
            f.puts dsl
          end
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
