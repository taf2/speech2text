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
        sprintf "%.2d:%.2d:%.2d:%.2d", self.hours.to_i, self.minutes.to_i, s.to_i, (f||0).to_i
        #"#{hours}:#{minutes}:#{seconds}:#{f}"
      end

      def to_f
        self.total_seconds
      end

      def self.from_seconds(seconds)
        duration = Duration.new("00:00:00.00")
        duration.hours = (seconds.to_i / 3600).to_i
        duration.minutes = (seconds / 60).to_i
        duration.seconds = (seconds - (duration.minutes*60) - (duration.hours*3600)).to_s
        duration.hours = duration.hours.to_s
        duration.minutes = duration.minutes.to_s

        duration
      end

    end

    def initialize(file)
      self.duration = Duration.new(`ffmpeg -i #{file} 2>&1`.strip.scan(/Duration: (.*),/).first.first)
    end

  end
end
