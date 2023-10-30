# coding: utf-8
# typed: strict
# frozen_string_literal: true

module PDF
  class Reader

    # In computer science, a disjoint-set data structure, also called a union–find data structure or merge–find set,
    # is a data structure that stores a collection of disjoint (non-overlapping) sets.
    class DisjointSet
      include Enumerable

      def initialize
        @parents = {}
        @ranks = {}
      end

      def contains(item)
        @parents.key?(item)
      end

      def each(&block)
        if block_given?
          @parents.each_key(&block)
        else
          to_enum(:each)
        end
      end

      def length
        @parents.length
      end

      def add(x)
        @parents[x] = x
        @ranks[x] = 0
        self
      end

      def find(x)
        return x if @parents[x] == x

        find(@parents[x])
      end

      def sets
        cluster_parents = {}
        @parents.each_key do |x|
          p = find(x)
          cluster_parents[p] = [] unless cluster_parents.key?(p)
          cluster_parents[p].push(x)
        end
        cluster_parents.values
      end

      def union(x, y)
        x_parent = find(x)
        y_parent = find(y)

        return self if x_parent == y_parent

        if @ranks[x_parent] > @ranks[y_parent]
          @parents[y_parent] = x_parent
        elsif @ranks[y_parent] > @ranks[x_parent]
          @parents[x_parent] = y_parent
        else
          @parents[y_parent] = x_parent
          @ranks[x_parent] += 1
        end

        self
      end
    end
  end
end
