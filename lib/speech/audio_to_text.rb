# -*- encoding: binary -*-
module Speech

  class AudioToText
    attr_accessor :file, :rate, :captured_json
    attr_accessor :best_match_text, :score, :verbose, :segments

    def initialize(file, options={})
      self.verbose = false
      self.file = file
      self.captured_json = {}
      self.best_match_text = ""
      self.score = 0.0
      self.segments = 0

      self.verbose = !!options[:verbose] if options.key?(:verbose)
    end

    def to_text(max=2,lang="en-US")
      to_json(max,lang)
      self.best_match_text if self.verbose
    end

    def to_json(max=2,lang="en-US")
      self.best_match_text = ""
      self.score = 0.0
      self.segments = 0

      url = "https://www.google.com/speech-api/v1/recognize?xjerr=1&client=speech2text&lang=#{lang}&maxresults=#{max}"
      splitter = Speech::AudioSplitter.new(file) # based off the wave file because flac doesn't tell us the duration
      easy = Curl::Easy.new(url)
      splitter.split.each do|chunk|
        chunk.build.to_flac
        convert_chunk(easy, chunk)
      end
      self.best_match_text = self.best_match_text.strip
      self.score /= self.segments
      self.captured_json
    end

  protected
    def convert_chunk(easy, chunk, options={})
      puts "sending chunk of size #{chunk.duration}..." if self.verbose
      retrying = true
      retry_count = 0
      while retrying && retry_count < 3 # 3 retries
        easy.verbose = self.verbose
        easy.headers['Content-Type'] = "audio/x-flac; rate=#{chunk.flac_rate}"
        easy.headers['User-Agent'] = "https://github.com/taf2/speech2text"
        easy.post_body = "Content=#{chunk.to_flac_bytes}"
        if self.verbose
          easy.on_progress {|dl_total, dl_now, ul_total, ul_now| printf("%.2f/%.2f\r", ul_now, ul_total); true }
        end
        easy.http_post
        if easy.response_code == 500
          puts "500 from google retry after 0.5 seconds" if self.verbose
          retrying = true
          retry_count += 1
          sleep 0.5 # wait longer on error?, google??
        else
          # {"status":0,"id":"ce178ea89f8b17d8e8298c9c7814700a-1","hypotheses":[{"utterance"=>"I like pickles", "confidence"=>0.59408695}, {"utterance"=>"I like turtles"}, {"utterance"=>"I like tickles"}, {"utterance"=>"I like to Kohl's"}, {"utterance"=>"I Like tickles"}, {"utterance"=>"I lyk tickles"}, {"utterance"=>"I liked to Kohl's"}]}
          data = JSON.parse(easy.body_str)
          self.captured_json['status'] = data['status']
          self.captured_json['id'] = data['id']
          self.captured_json['hypotheses'] = data['hypotheses'].map {|ut| [ut['utterance'], ut['confidence']] } 
          if data.key?('hypotheses') && data['hypotheses'].first
            self.best_match_text += " " + data['hypotheses'].first['utterance']
            self.score += data['hypotheses'].first['confidence']
            self.segments += 1
            puts data['hypotheses'].first['utterance']
          end
          retrying = false
        end
        sleep 0.1 # not too fast there tiger
      end
      puts "#{segments} processed: #{self.captured_json.inspect}" if self.verbose
      self.captured_json
    ensure
      chunk.clean
    end

  end

end
