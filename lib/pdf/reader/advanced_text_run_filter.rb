# coding: utf-8
# frozen_string_literal: true
# typed: strict

class PDF::Reader
  # Filter a collection of TextRun objects based on a set of conditions.
  # It can be used to filter text runs based on their attributes.
  # The filter can return the text runs that matches the conditions (only) or
  # the text runs that do not match the conditions (exclude).
  #
  # You can filter the text runs based on all its attributes with the operators
  # mentioned in VALID_OPERATORS.
  # The filter can be nested with 'or' and 'and' conditions.
  #
  # Examples:
  # 1. Single condition
  # AdvancedTextRunFilter.exclude(text_runs, text: { include: 'sample' })
  #
  # 2. Multiple conditions (and)
  # AdvancedTextRunFilter.exclude(text_runs, {
  #   font_size: { greater_than: 10, less_than: 15 }
  # })
  #
  # 3. Multiple possible values (or)
  # AdvancedTextRunFilter.exclude(text_runs, {
  #  font_size: { equal: [10, 12] }
  # })
  #
  # 4. Complex AND/OR filter
  # AdvancedTextRunFilter.exclude(text_runs, {
  #   and: [
  #     { font_size: { greater_than: 10 } },
  #     { or: [
  #       { text: { include: "sample" } },
  #       { width: { greater_than: 100 } }
  #     ]}
  #   ]
  # })
  class AdvancedTextRunFilter
    VALID_OPERATORS = %i[
      equal
      not_equal
      greater_than
      less_than
      greater_than_or_equal
      less_than_or_equal
      include
      exclude
    ]

    def self.only(text_runs, filter_hash)
      new(text_runs, filter_hash).only
    end

    def self.exclude(text_runs, filter_hash)
      new(text_runs, filter_hash).exclude
    end

    attr_reader :text_runs, :filter_hash

    def initialize(text_runs, filter_hash)
      @text_runs = text_runs
      @filter_hash = filter_hash
    end

    def only
      return text_runs if filter_hash.empty?
      text_runs.select { |text_run| evaluate_filter(text_run) }
    end

    def exclude
      return text_runs if filter_hash.empty?
      text_runs.reject { |text_run| evaluate_filter(text_run) }
    end

    private

    def evaluate_filter(text_run)
      if filter_hash[:or]
        evaluate_or_filters(text_run, filter_hash[:or])
      elsif filter_hash[:and]
        evaluate_and_filters(text_run, filter_hash[:and])
      else
        evaluate_filters(text_run, filter_hash)
      end
    end

    def evaluate_or_filters(text_run, conditions)
      conditions.any? do |condition|
        evaluate_filters(text_run, condition)
      end
    end

    def evaluate_and_filters(text_run, conditions)
      conditions.all? do |condition|
        evaluate_filters(text_run, condition)
      end
    end

    def evaluate_filters(text_run, filter_hash)
      filter_hash.all? do |attribute, conditions|
        evaluate_attribute_conditions(text_run, attribute, conditions)
      end
    end

    def evaluate_attribute_conditions(text_run, attribute, conditions)
      conditions.all? do |operator, value|
        unless VALID_OPERATORS.include?(operator)
          raise ArgumentError, "Invalid operator: #{operator}"
        end

        apply_operator(text_run.send(attribute), operator, value)
      end
    end

    def apply_operator(attribute_value, operator, filter_value)
      case operator
      when :equal
        Array(filter_value).include?(attribute_value)
      when :not_equal
        !Array(filter_value).include?(attribute_value)
      when :greater_than
        attribute_value > filter_value
      when :less_than
        attribute_value < filter_value
      when :greater_than_or_equal
        attribute_value >= filter_value
      when :less_than_or_equal
        attribute_value <= filter_value
      when :include
        Array(filter_value).any? { |v| attribute_value.to_s.include?(v.to_s) }
      when :exclude
        Array(filter_value).none? { |v| attribute_value.to_s.include?(v.to_s) }
      end
    end
  end
end
