# encoding: utf-8
#

require 'bigdecimal'

module PDF
  module Preflight
    module Measurements

      private

      # convert inches to standard PDF points
      #
      def in2pt(inch)
        return inch * BigDecimal.new("72")
      end

      # convert mm to standard PDF points
      #
      def mm2pt(mm)
        return mm * (BigDecimal.new("72") / BigDecimal.new("24.4"))
      end

      # convert mm to standard PDF points
      #
      def cm2pt(cm)
        return cm * mm2pt(10)
      end

      # convert standard PDF points to inches
      #
      def pt2in(pt)
        return pt / in2pt(1)
      end

      # convert standard PDF points to mm
      #
      def pt2mm(pt)
        return pt / mm2pt(1)
      end

      # convert standard PDF points to cm
      #
      def pt2cm(pt)
        return pt / cm2pt(1)
      end
    end
  end
end
