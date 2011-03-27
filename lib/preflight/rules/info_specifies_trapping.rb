# coding: utf-8

module Preflight
  module Rules
    class InfoSpecifiesTrapping

      def self.rule_type
        :hash
      end

      def messages(ohash)
        info = ohash.object(ohash.trailer[:Info])

        if !info.has_key?(:Trapped)
          [ "Info dict does not specify Trapped" ]
        elsif info[:Trapped] != :True && info[:Trapped] != :False
          [ "Trapped value of Info dict must be True or False" ]
        else
          []
        end
      end
    end
  end
end
