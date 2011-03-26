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

      def error(*args)
        errors << args.flatten
      end

      def warn(*args)
      end

      def errors
        @errors ||= []
      end

      def warnings
        @warnings ||= []
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

      private

      def check_filename(filename)
        File.open(filename, "rb") do |file|
          return check_io(file)
        end
      end

      def check_io(io)
        check_receivers(io) + check_hash(io)
      end

      # TODO: this is nasty, we parse the full file once for each receiver.
      #       PDF::Reader needs to be updated to support multiple receivers
      #
      def check_receivers(io)
        receiver_rules.map { |rec|
          begin
            PDF::Reader.new.parse(io, rec)
            rec.message
          rescue PDF::Reader::UnsupportedFeatureError
            nil
          end
        }.compact
      end

      def check_hash(io)
        ohash = PDF::Reader::ObjectHash.new(io)

        hash_rules.map { |chk|
          chk.message(ohash)
        }.compact
      end

      def hash_rules
        (self.class.errors + self.class.warnings).select { |arr|
          arr.first.rule_type == :hash
        }.map { |arr|
          klass = arr[0]
          klass.new(*arr[1,10])
        }
      end

      def receiver_rules
        (self.class.errors + self.class.warnings).select { |arr|
          arr.first.rule_type == :receiver
        }.map { |arr|
          klass = arr[0]
          klass.new(*arr[1,10])
        }
      end
    end
  end
end
