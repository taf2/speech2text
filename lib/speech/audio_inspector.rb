# -*- encoding: binary -*-
module Speech

  class AudioInspector
    attr_accessor :duration

    class Duration
      attr_accessor :hours, :minutes, :seconds, :total_seconds

      def initialize(duration_str)
        self.hours, self.minutes, self.seconds = duration_str.split(':')
        self.total_seconds = (self.hours.to_i * 3600) + (self.minutes.to_i * 60) + self.seconds.to_f
      end

      def to_s
        s,f = seconds.split('.')
        sprintf "%.2d:%.2d:%.2d.%.2d", self.hours.to_i, self.minutes.to_i, s.to_i, (f||0).to_i
        #"#{hours}:#{minutes}:#{seconds}:#{f}"
      end

      def to_f
        (self.hours.to_i * 3600) + (self.minutes.to_i * 60) + self.seconds.to_f
      end

      def self.from_seconds(seconds)
#        puts "total seconds: #{seconds.inspect}"
        duration = Duration.new("00:00:00.00")
        duration.hours = (seconds.to_i / 3600).to_i
#        puts "hours: #{duration.hours.inspect}"
        duration.minutes = ((seconds.to_i - (duration.hours*3600)) / 60).to_i
#        puts "minutes: #{duration.minutes.inspect}"
        secs = (seconds - (duration.minutes*60) - (duration.hours*3600))
        duration.seconds = sprintf("%.2f", secs)
#        puts "seconds: #{duration.seconds.inspect}"
        duration.hours = duration.hours.to_s
        duration.minutes = duration.minutes.to_s

        duration
      end

      def +(b)
        total = self.to_f + b.to_f
#        puts "total: #{self.to_f} + #{b.to_f} = #{total.inspect}"
        Duration.from_seconds(self.to_f + b.to_f)
      end

    end

    def initialize(file)
      out = `ffmpeg -i #{file} 2>&1`.strip
      if out.match(/No such file or directory/)
        raise "No such file or directory: #{file}"
      else
        out = out.scan(/Duration: (.*),/)
        self.duration = Duration.new(out.first.first)
      end
    end

  end
end

if $0 == __FILE__
  require 'test/unit'

  class QuickTest < Test::Unit::TestCase

    def test_add_duration
      a = Speech::AudioInspector::Duration.new("00:00:12.12")
      b = Speech::AudioInspector::Duration.new("00:00:02.00")

      assert_equal "00:00:14:12", (a + b).to_s

      a = Speech::AudioInspector::Duration.new("00:10:12.12")
      b = Speech::AudioInspector::Duration.new("08:00:02.00")

      assert_equal "08:10:14:12", (a + b).to_s

      a = Speech::AudioInspector::Duration.new("02:10:12.12")
      b = Speech::AudioInspector::Duration.new("08:55:02.10")

      assert_equal "11:05:14:22", (a + b).to_s

      a = Speech::AudioInspector::Duration.new("00:00:12.12")
      b = Speech::AudioInspector::Duration.new("00:00:02.00")

      a = a + b
      assert_equal "00:00:14:12", a.to_s
      puts a.inspect

      a = a + b
      puts a.inspect

      assert_equal "00:00:16:12", a.to_s

      a = a + b
      puts a.to_s
      assert_equal "00:00:18:12", a.to_s
      puts a.to_s
    end

  end
end
