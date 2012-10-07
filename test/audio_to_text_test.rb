# -*- encoding: binary -*-
require 'test/unit'
$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'speech'

class SpeechAudioToTextTest < Test::Unit::TestCase
  def setup
    super
  end

  def test_audio_to_text
    audio = Speech::AudioToText.new(File.expand_path(File.join(File.dirname(__FILE__),"samples/i-like-pickles.wav")))
    assert_equal "I like pickles", audio.to_text
  end

  def test_longer_audio
    audio = Speech::AudioToText.new(File.expand_path(File.join(File.dirname(__FILE__),"/SampleAudio.wav")), :verbose => true)
    puts audio.to_text
    puts audio.score
    puts audio.segments
  end
end
