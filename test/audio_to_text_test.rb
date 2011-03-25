# -*- encoding: binary -*-
require 'test/unit'
$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'speech'

class SpeechAudioToTextTest < Test::Unit::TestCase
  def test_audio_to_text
    audio = Speech::AudioToText.new("samples/i-like-pickles.wav")
    captured_json = audio.to_text
    assert captured_json
    assert captured_json.key?("captured_json")
    assert !captured_json['captured_json'].empty?
    assert_equal ['captured_json', 'confidence'], captured_json.keys.sort
    assert_equal "I like pickles", captured_json['captured_json'].flatten.first
    assert captured_json['confidence'] > 0.9
#    {"captured_json"=>[["I like pickles", 0.92731786]], "confidence"=>0.92731786}
#    puts captured_json.inspect
  ensure
    audio.clean
  end
end
