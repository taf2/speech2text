# -*- encoding: binary -*-
require 'test/unit'
$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'speech'

class SpeechAudioSplitterTest < Test::Unit::TestCase

  def test_audio_splitter
    splitter = Speech::AudioSplitter.new(File.expand_path(File.join(File.dirname(__FILE__),"samples/i-like-pickles.wav")), 1)

    assert_equal '00:00:03.51', splitter.duration.to_s
    assert_equal 3.51, splitter.duration.to_f

    chunks = splitter.split
    assert_equal 3, chunks.size
    chunks.each do|chunk|
      chunk.build.to_flac
      assert File.exist? chunk.chunk
      assert File.exist? chunk.flac_chunk
      chunk.clean
      assert !File.exist?(chunk.chunk)
      assert !File.exist?(chunk.flac_chunk)
    end
  end

end
