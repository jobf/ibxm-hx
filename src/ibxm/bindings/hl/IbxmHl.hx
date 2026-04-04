package ibxm.bindings.hl;

import haxe.io.Bytes;
import audio.IReplaySource;

@:hlNative("ibxmHl") extern class C {
	static function get_version():hl.Bytes;

	static function initialise(data:hl.Bytes, file_length:Int, sample_rate:Int, interpolation:Int):Int;

	static function get_instrument(instrument:Int):hl.Bytes;

	static function calculate_song_duration():Int;

	static function get_audio(output_buffer:hl.Bytes, sample_count:Int):Void;

	static function set_position(pos:Int):Void;

	static function seek(sample_pos:Int):Int;

	static function get_name():hl.Bytes;

	static function calculate_mix_buf_len(sample_rate:Int):Int;

	static function set_muted(channel:Int, muted:Bool):Void;

	static function is_muted(channel:Int):Bool;

	static function get_num_patterns():Int;

	static function get_sequence(output:hl.Bytes):Void;

	static function get_instrument_data(index:Int, output:hl.Bytes):Void;

	static function get_sample_data(instrument:Int, sample:Int, output:hl.Bytes):Void;

	static function get_num_channels():Int;

	static function get_num_instruments():Int;

	static function get_sequence_length():Int;

	static function get_sequence_pos():Int;

	static function get_row():Int;

	static function get_pattern_num_rows(seqPos:Int):Int;

	static function get_pattern_data(seqPos:Int, output:hl.Bytes):Void;
}

@:publicFields
class IbxmHl {
	static function get_version():String {
		var string = C.get_version();
		@:privateAccess
		return String.fromUTF8(string);
	}

	static function initialise(module:haxe.io.Bytes, sampleRate:Int):Int {
		var interpolation:Int = 0;
		return C.initialise(module, module.length, sampleRate, interpolation);
	}

	static function get_instrument_name(instrument:Int):String {
		var string = C.get_instrument(instrument);
		@:privateAccess
		return String.fromUTF8(string);
	}

	static function calculate_song_duration():Int {
		return C.calculate_song_duration();
	}

	static function get_audio(output_buffer:haxe.io.Bytes, sample_count:Int) {
		// trace('C.get_audio');
		C.get_audio(output_buffer, sample_count);
	}

	static function set_position(pattern:Int) {
		C.set_position(pattern);
	}

	static function seek(samplePosition:Int):Int {
		return C.seek(samplePosition);
	}

	static function get_name():String {
		var string = C.get_name();
		@:privateAccess
		return String.fromUTF8(string);
	}

	static function calculate_mix_buffer_len(sample_rate:Int):Int {
		return C.calculate_mix_buf_len(sample_rate);
	}

	static function set_muted(channel:Int, muted:Bool):Void {
		C.set_muted(channel, muted);
	}

	static function is_muted(channel:Int):Bool {
		return C.is_muted(channel);
	}

	static function get_num_patterns():Int {
		return C.get_num_patterns();
	}

	static function get_sequence():Array<Int> {
		var len = C.get_sequence_length();
		var buf = haxe.io.Bytes.alloc(len * 4);
		C.get_sequence(buf);
		return [for (i in 0...len) buf.getInt32(i * 4)];
	}

	static inline final STRUCT_BUFFER_SIZE = 56;

	static function get_instrument(index:Int):ibxm.Instrument {
		var buf = haxe.io.Bytes.alloc(STRUCT_BUFFER_SIZE);
		C.get_instrument_data(index, buf);
		return ibxm.Instrument.fromBytes(buf);
	}

	static function get_sample(instrument:Int, sample:Int):ibxm.Sample {
		var buf = haxe.io.Bytes.alloc(STRUCT_BUFFER_SIZE);
		C.get_sample_data(instrument, sample, buf);
		return ibxm.Sample.fromBytes(buf);
	}

	static function get_num_channels():Int {
		return C.get_num_channels();
	}

	static function get_num_instruments():Int {
		return C.get_num_instruments();
	}

	static function get_sequence_length():Int {
		return C.get_sequence_length();
	}

	static function get_sequence_pos():Int {
		return C.get_sequence_pos();
	}

	static function get_row():Int {
		return C.get_row();
	}

	static function get_pattern_num_rows(seqPos:Int):Int {
		return C.get_pattern_num_rows(seqPos);
	}

	static function get_pattern_data(seqPos:Int):haxe.io.Bytes {
		var numRows = C.get_pattern_num_rows(seqPos);
		var numChannels = C.get_num_channels();
		var buf = haxe.io.Bytes.alloc(numChannels * numRows * 5);
		C.get_pattern_data(seqPos, buf);
		return buf;
	}

	static function get_source():IReplaySource {
		return new IbxmSource((interleaved, count) -> get_audio(interleaved, count));
	}
}

@:publicFields
class IbxmSource implements IReplaySource {
	var get_audio:(interleaved:Bytes, count:Int) -> Void;

	function new(audioCallback:(interleaved:Bytes, count:Int) -> Void) {
		this.get_audio = audioCallback;
	}

	function calculateSongDuration():Int {
		return IbxmHl.calculate_song_duration();
	}

	function calculateMixBufferLen(sampleRate:Int):Int {
		return IbxmHl.calculate_mix_buffer_len(sampleRate);
	}

	function getAudio(interleavedBuf:Bytes, count:Int):Void {
		get_audio(interleavedBuf, count);
	}
}
