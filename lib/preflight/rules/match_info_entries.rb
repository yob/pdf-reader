# coding: utf-8

module Preflight
  module Rules
    class MatchInfoEntries

      def initialize(matches = {})
        @matches = matches
      end

      def check_hash(ohash)
        array = []
        info = ohash.object(ohash.trailer[:Info])
        @matches.each do |key, regexp|
          if !info.has_key?(key)
            array << "Info dict missing required key #{key}"
          elsif !info[key].to_s.match(regexp)
            array << "value of Info entry #{key} doesn't match (#{info[key]} != #{regexp})"
          end
        end
        array
      end
    end
  end
end
