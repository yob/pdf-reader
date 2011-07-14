# coding: utf-8

module Preflight

  # base functionality for all profiles.
  #
  module Profile

    def self.included(base) # :nodoc:
      base.class_eval do
        extend  Preflight::Profile::ClassMethods
        include InstanceMethods
      end
    end

    module ClassMethods
      def profile_name(str)
        @profile_name = str
      end

      def import(profile)
        profile.rules.each do |array|
          rules << array.flatten
        end
      end

      def rule(*args)
        rules << args.flatten
      end

      def rules
        @rules ||= []
      end

    end

    module InstanceMethods
      def check(input)
        if File.file?(input)
          check_filename(input)
        elsif input.is_a?(IO)
          check_io(input)
        else
          raise ArgumentError, "input must be a string with a filename or an IO object"
        end
      end

      def rule(*args)
        instance_rules << args.flatten
      end

      private

      def check_filename(filename)
        File.open(filename, "rb") do |file|
          return check_io(file)
        end
      end

      def check_io(io)
        PDF::Reader.open(io) do |reader|
          check_receivers(reader) + check_pages(reader) + check_hash(reader)
        end
      end

      def instance_rules
        @instance_rules ||= []
      end

      def all_rules
        self.class.rules + instance_rules
      end

      def check_hash(reader)
        hash_rules.map { |chk|
          chk.check_hash(reader.objects)
        }.flatten.compact
      rescue PDF::Reader::UnsupportedFeatureError
        []
      end

      def check_pages(reader)
        rules_array = page_rules

        reader.pages.map { |page|
          page_rules.map { |rule|
            rule.check_page(page)
          }.flatten.compact
        }.flatten.compact
      rescue PDF::Reader::UnsupportedFeatureError
        []
      end

      def check_receivers(reader)
        rules_array = receiver_rules
        messages    = []

        begin
          reader.pages.each do |page|
            page.walk(rules_array)
            messages += rules_array.map(&:messages).flatten.compact
          end
        rescue PDF::Reader::UnsupportedFeatureError
          nil
        end
        messages
      end

      def hash_rules
        all_rules.select { |arr|
          arr.first.instance_methods.map(&:to_sym).include?(:check_hash)
        }.map { |arr|
          klass = arr[0]
          klass.new(*arr[1,10])
        }
      end

      def page_rules
        all_rules.select { |arr|
          arr.first.instance_methods.map(&:to_sym).include?(:check_page)
        }.map { |arr|
          klass = arr[0]
          klass.new(*arr[1,10])
        }
      end

      def receiver_rules
        all_rules.select { |arr|
          arr.first.instance_methods.map(&:to_sym).include?(:messages)
        }.map { |arr|
          klass = arr[0]
          klass.new(*arr[1,10])
        }
      end
    end
  end
end
