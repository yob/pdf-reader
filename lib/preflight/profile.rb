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
        check_receivers(io) + check_hash(io)
      end

      def instance_rules
        @instance_rules ||= []
      end

      def all_rules
        self.class.rules + instance_rules
      end

      # TODO: this is nasty, we parse the full file once for each receiver.
      #       PDF::Reader needs to be updated to support multiple receivers
      #
      def check_receivers(io)
        receiver_rules.map { |rec|
          begin
            PDF::Reader.new.parse(io, rec)
            rec.messages
          rescue PDF::Reader::UnsupportedFeatureError
            nil
          end
        }.flatten.compact
      end

      def check_hash(io)
        ohash = PDF::Reader::ObjectHash.new(io)

        hash_rules.map { |chk|
          chk.messages(ohash)
        }.flatten.compact
      end

      def hash_rules
        all_rules.select { |arr|
          meth = arr.first.instance_method(:messages)
          meth && meth.arity == 1
        }.map { |arr|
          klass = arr[0]
          klass.new(*arr[1,10])
        }
      end

      def receiver_rules
        all_rules.select { |arr|
          meth = arr.first.instance_method(:messages)
          meth && meth.arity == 0
        }.map { |arr|
          klass = arr[0]
          klass.new(*arr[1,10])
        }
      end
    end
  end
end
