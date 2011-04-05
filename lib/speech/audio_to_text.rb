# -*- encoding: binary -*-
module Speech

  class AudioToText
    attr_accessor :file, :rate, :captured_json, :captured_file

    def initialize(file)
      self.file = file
      self.captured_file = self.file.gsub(/\.wav$/,'.json')
      self.captured_json = {}
    end

    def to_text
      url = "https://www.google.com/speech-api/v1/recognize?xjerr=1&client=speech2text&lang=en-US&maxresults=10"
      splitter = Speech::AudioSplitter.new(file) # based off the wave file because flac doesn't tell us the duration
      easy = Curl::Easy.new(url)
      splitter.split.each do|chunk|
        chunk.build.to_flac
        convert_chunk(easy, chunk)
      end
      JSON.parse(File.read(self.captured_file))
    end

    def clean
      File.unlink self.captured_file if self.captured_file && File.exist?(self.captured_file)
    end

  protected

    def convert_chunk(easy, chunk, options={})
      puts "sending chunk of size #{chunk.duration}..."
      retrying = true
      retry_count = 0
      while retrying && retry_count < 5
        #easy.verbose = true
        easy.headers['Content-Type'] = "audio/x-flac; rate=#{chunk.flac_rate}"
        easy.headers['User-Agent'] = "https://github.com/taf2/speech2text"
        #puts chunk.inspect
        easy.post_body = "Content=#{chunk.to_flac_bytes}"
        easy.on_progress {|dl_total, dl_now, ul_total, ul_now| printf("%.2f/%.2f\r", ul_now, ul_total); true }
        easy.on_complete {|easy| puts }
        easy.http_post
        #puts easy.header_str
        #puts easy.body_str
        if easy.response_code == 500
          puts "500 from google retry after 0.5 seconds"
          retrying = true
          retry_count += 1
          sleep 0.5 # wait longer on error?, google??
        else
          # {"status":0,"id":"ce178ea89f8b17d8e8298c9c7814700a-1","hypotheses":[{"utterance":"I like pickles","confidence":0.92731786}]}
          data = JSON.parse(easy.body_str)
          self.captured_json['status'] = data['status']
          self.captured_json['id'] = data['id']
          self.captured_json['hypotheses'] = data['hypotheses'].map {|ut| [ut['utterance'], ut['confidence']] } 
          puts self.captured_json.inspect
          File.open("#{self.captured_file}", "wb") {|f| f << captured_json.to_json }
          retrying = false
        end
        sleep 0.1 # not too fast there tiger
      end
    ensure
      chunk.clean
    end

  end

end
