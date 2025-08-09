# coding: utf-8
# typed: strict
# frozen_string_literal: true

class PDF::Reader
  # A simple receiver that prints all operaters and parameters in the content
  # stream of a single page.
  #
  class PrintReceiver

    #: (untyped) -> bool
    def respond_to?(meth)
      true
    end

    #: (Symbol, *untyped) -> void
    def method_missing(methodname, *args)
      puts "#{methodname} => #{args.inspect}"
    end
  end
end
