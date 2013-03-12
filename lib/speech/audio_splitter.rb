# -*- encoding: binary -*-
module Speech

  class AudioSplitter
    attr_accessor :original_file, :size, :duration, :chunks

    class AudioChunk
      attr_accessor :splitter, :chunk, :flac_chunk, :offset, :duration, :flac_rate, :copied

      def initialize(splitter, offset, duration)
        self.offset = offset
        self.chunk = File.join("/tmp/" + UUID.generate + "-chunk-" + File.basename(splitter.original_file).gsub(/\.(.*)$/, "-#{offset}" + '.\1'))
        self.duration = duration
        self.splitter = splitter
        self.copied = false
      end

      def self.copy(splitter)
        chunk = AudioChunk.new(splitter, 0, splitter.duration.to_f)
        chunk.copied = true
        system("cp #{splitter.original_file} #{chunk.chunk}")
        chunk
      end

      # given the original file from the splitter and the chunked file name with duration and offset run the ffmpeg command
      def build
        return self if self.copied
        # ffmpeg -y -i sample.audio.wav -acodec copy -vcodec copy -ss 00:00:00.00 -t 00:00:30.00 sample.audio.out.wav
        offset_ts = AudioInspector::Duration.from_seconds(self.offset).to_s
        duration_ts = AudioInspector::Duration.from_seconds(self.duration).to_s
        # NOTE: kind of a hack, but if the original source is less than or equal to 1 second, we should skip ffmpeg
        #puts "building chunk: #{duration_ts.inspect} and offset: #{offset_ts}"
        #puts "offset: #{ offset_ts.to_s }, duration: #{duration_ts.to_s}"
        cmd = "ffmpeg -y -i #{splitter.original_file} -acodec copy -vcodec copy -ss #{offset_ts} -t #{duration_ts} #{self.chunk}   >/dev/null 2>&1"
        if system(cmd)
          self
        else
          raise "Failed to generate chunk at offset: #{offset_ts}, duration: #{duration_ts}\n#{cmd}"
        end
      end

      # convert the audio file to flac format
      def to_flac
        chunk_outputfile = chunk.gsub(/#{File.extname(chunk)}$/, ".flac")
        if system("ffmpeg -i #{chunk} -acodec flac #{chunk_outputfile} >/dev/null 2>&1")
          self.flac_chunk = chunk.gsub(/#{File.extname(chunk)}$/, ".flac")
          # convert the audio file to 16K
          self.flac_rate = `ffmpeg -i #{self.flac_chunk} 2>&1`.strip.scan(/Audio: flac, (.*) Hz/).first.first.strip
          down_sampled = self.flac_chunk.gsub(/\.flac$/, '-sampled.flac')
          if system("ffmpeg -i #{self.flac_chunk} -ar 16000 -y #{down_sampled} >/dev/null 2>&1")
            system("mv #{down_sampled} #{self.flac_chunk} 2>&1 >/dev/null")
            self.flac_rate = 16000
          else
            raise "failed to convert to lower audio rate"
          end

        else
          raise "failed to convert chunk: #{chunk} with flac #{chunk}"
        end
      end

      def to_flac_bytes
        File.read(self.flac_chunk)
      end

      # delete the chunk file
      def clean
        File.unlink self.chunk if File.exist?(self.chunk)
        File.unlink self.flac_chunk if self.flac_chunk && File.exist?(self.flac_chunk)
      end

    end

    def initialize(file, chunk_size=5)
      self.original_file = file      
      self.duration = AudioInspector.new(file).duration
      self.size = chunk_size
      self.chunks = []
    end

    def split
      # compute the total number of chunks
      full_chunks = (self.duration.to_f / size).to_i
      last_chunk = ((self.duration.to_f % size) * 100).round / 100.0
      #puts "generate: #{full_chunks} chunks of #{size} seconds, last: #{last_chunk} seconds"

      (full_chunks-1).times do |chunkid|
        if chunkid > 0
          chunks << AudioChunk.new(self, chunkid * self.size, self.size)
        else
          off = (chunkid * self.size)-(self.size/2)
          off = 0 if off < 0
          chunks << AudioChunk.new(self, off, self.size)
        end
      end

      if chunks.empty?
        chunks << AudioChunk.copy(self)#, 0, self.duration.to_f)
      else
        chunks << AudioChunk.new(self, chunks.last.offset.to_i + chunks.last.duration.to_i, self.size + last_chunk)
      end
      #puts "Chunk count: #{chunks.size}"

      chunks
    end

  end
end
