class PDF::Reader

  class SweepLineStatus < Array
    def report_intersection event_point
      self.each do |point_in_sls|
        sweepline_range = (point_in_sls.run.x...point_in_sls.run.endx)
        if sweepline_range.include? event_point.x
          puts "Sweepline of #{point_in_sls.run.inspect} intersects with sweepline of #{event_point.run.inspect}"
          puts "\t --> #{point_in_sls.run.inspect} really intersects with #{event_point.run.inspect}" if point_in_sls.run.intersect? event_point.run
        end
      end
    end
  end

  class EventPoint
    attr_reader :x, :run

    def initialize x, run
      @x, @run = x, run
    end

    def starts?
      @x == @run.x
    end

    def to_s
      beginning_or_end = starts? ? "begin of" : "end of"
      "(#{x} #{beginning_or_end} #{@run.inspect})"
    end
  end

  class OverlappingRunsFilter
    
    def self.exclude_redundant_runs(runs)
      sweep_line_status = SweepLineStatus.new
      event_point_schedule = Array.new

      runs.each do |run|
        event_point_schedule << EventPoint.new(run.x, run)
        event_point_schedule << EventPoint.new(run.endx, run)
      end

      event_point_schedule.sort! { |a,b| a.x <=> b.x }

      while not event_point_schedule.empty? do
        event_point = event_point_schedule.shift
        break unless event_point

        if event_point.starts? then
          sweep_line_status.report_intersection event_point
          sweep_line_status.push event_point
        else
          sweep_line_status.delete event_point
        end
      end
      runs
    end
  end

end
