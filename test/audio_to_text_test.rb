# -*- encoding: binary -*-
require 'test/unit'
$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'speech'

class SpeechAudioToTextTest < Test::Unit::TestCase
  def test_audio_to_text
    audio = Speech::AudioToText.new("test/samples/i-like-pickles.wav")
    captured_json = audio.to_text
    assert captured_json
    assert captured_json.key?("hypotheses")
    assert !captured_json['hypotheses'].empty?
    assert captured_json.keys.include?('status')
    assert captured_json.keys.include?('id')
    assert captured_json.keys.include?('hypotheses')

    assert_equal "I like pickles", captured_json['hypotheses'].first.first
    assert captured_json['hypotheses'].first.last > 0.9
#    {"hypotheses"=>[["I like pickles", 0.92731786]]}
#    puts captured_json.inspect
  ensure
    audio.clean
  end

  def test_short_audio_clip
    audio = Speech::AudioToText.new("samples/i-like-pickles.chunk5.wav")
    captured_json = audio.to_text
    assert captured_json
    assert captured_json.key?("hypotheses")
    assert !captured_json['hypotheses'].empty?
    #{"status"=>0, "id"=>"552de5ba35bb769ce3493ff113e158a8-1", "hypotheses"=>[["eagles", 0.7214844], ["pickles", nil], ["michaels", nil], ["giggles", nil], ["tickles", nil]]}
    assert captured_json.keys.include?('status')
    assert captured_json.keys.include?('id')
    assert captured_json.keys.include?('hypotheses')
    puts captured_json.inspect
    assert_equal "eagles eagles eagles", captured_json['hypotheses'][0].first
    assert_equal "pickles pickles pickles", captured_json['hypotheses'][1].first
    #assert captured_json['confidence'] > 0.9
  ensure
    audio.clean
  end
end
