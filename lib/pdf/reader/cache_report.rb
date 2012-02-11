# coding: utf-8

class PDF::Reader

  # A utility class for sorting and printing the data returned
  # by ObjectHash#cache_stats
  #
  class CacheReport

    def initialize(stats)
      @stats = stats
    end

    def to_s
      "reference,hits,misses,total\n" +
      sorted_by_access_count.map { |row|
        ref, hits, misses, total = *row
        [
          "\"#{ref.id}:#{ref.gen}\"",
          "#{hits}",
          "#{misses}",
          "#{total}"
        ].join(",")
      }.join("\n")
    end

    def save(path)
      File.open(path,"wb") do |file|
        file.write to_s
      end
    end

    private

    def header
      [
        " reference ".ljust(12),
        " hits ".rjust(10),
        " misses ".rjust(10),
        " total ".rjust(10),
      ].join("|")
    end

    def sorted_by_access_count
      @stats.map { |key, value|
        [key, value[:hits], value[:misses], value[:hits] + value[:misses]]
      }.sort_by { |row|
        row.last
      }.reverse
    end
  end
end
