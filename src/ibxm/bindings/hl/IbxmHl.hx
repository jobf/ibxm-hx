package ibxm.bindings.hl;

import haxe.io.Bytes;
import audio.IReplaySource;

@:hlNative("ibxmHl") extern class C {
	static function get_version():hl.Bytes;

	static function initialise(data:hl.Bytes, file_length:Int, sample_rate:Int, interpolation:Int):Int;

	static function get_instrument(instrument:Int):hl.Bytes;

	static function calculate_song_duration():Int;

	static function get_audio(output_buffer:hl.Bytes, len:Int):Void;

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
	static function getVersion():String {
		var string = C.get_version();
		@:privateAccess
		return String.fromUTF8(string);
	}

	static function initialise(module:haxe.io.Bytes, sampleRate:Int, interpolation:Bool):Int {
		return C.initialise(module, module.length, sampleRate, interpolation ? 1 : 0);
	}

	static function getInstrumentName(instrument:Int):String {
		var string = C.get_instrument(instrument);
		@:privateAccess
		return String.fromUTF8(string);
	}

	static function calculateSongDuration():Int {
		return C.calculate_song_duration();
	}

	static function setPosition(pattern:Int) {
		C.set_position(pattern);
	}

	static function seek(samplePosition:Int):Int {
		return C.seek(samplePosition);
	}

	static function getName():String {
		var string = C.get_name();
		@:privateAccess
		return String.fromUTF8(string);
	}

	static function calculateMixBufferLen(sampleRate:Int):Int {
		return C.calculate_mix_buf_len(sampleRate);
	}

	static function setMuted(channel:Int, muted:Bool):Void {
		C.set_muted(channel, muted);
	}

	static function isMuted(channel:Int):Bool {
		return C.is_muted(channel);
	}

	static function getNumPatterns():Int {
		return C.get_num_patterns();
	}

	static function getSequence():Array<Int> {
		var len = C.get_sequence_length();
		var buf = haxe.io.Bytes.alloc(len * 4);
		C.get_sequence(buf);
		return [for (i in 0...len) buf.getInt32(i * 4)];
	}

	static inline final STRUCT_BUFFER_SIZE = 56;

	static function getInstrument(index:Int):ibxm.Instrument {
		var buf = haxe.io.Bytes.alloc(STRUCT_BUFFER_SIZE);
		C.get_instrument_data(index, buf);
		return ibxm.Instrument.fromBytes(buf);
	}

	static function getSample(instrument:Int, sample:Int):ibxm.Sample {
		var buf = haxe.io.Bytes.alloc(STRUCT_BUFFER_SIZE);
		C.get_sample_data(instrument, sample, buf);
		return ibxm.Sample.fromBytes(buf);
	}

	static function getNumChannels():Int {
		return C.get_num_channels();
	}

	static function getNumInstruments():Int {
		return C.get_num_instruments();
	}

	static function getSequenceLength():Int {
		return C.get_sequence_length();
	}

	static function getSequencePos():Int {
		return C.get_sequence_pos();
	}

	static function getRow():Int {
		return C.get_row();
	}

	static function getPatternNumRows(seqPos:Int):Int {
		return C.get_pattern_num_rows(seqPos);
	}

	static function getPatternData(seqPos:Int):haxe.io.Bytes {
		var numRows = C.get_pattern_num_rows(seqPos);
		var numChannels = C.get_num_channels();
		var buf = haxe.io.Bytes.alloc(numChannels * numRows * 5);
		C.get_pattern_data(seqPos, buf);
		return buf;
	}

	static function getSource():IReplaySource {
		return new IbxmSource();
	}
}

@:publicFields
class IbxmSource implements IReplaySource {
	static inline final CHUNK = 2048;
	final chunkBuf = haxe.io.Bytes.alloc(CHUNK * 4);

	function new() {}

	function calculateSequenceLength():Int {
		return IbxmHl.calculateSongDuration();
	}

	function calculateMixBufferLength(sampleRate:Int):Int {
		return IbxmHl.calculateMixBufferLen(sampleRate);
	}

	function getAudio(left:haxe.io.Float32Array, right:haxe.io.Float32Array, numSamples:Int):Void {
		var offset = 0;
		while (offset < numSamples) {
			var chunk = numSamples - offset;
			if (chunk > CHUNK) chunk = CHUNK;
			C.get_audio(chunkBuf, chunk * 4);
			for (i in 0...chunk) {
				var l = chunkBuf.getUInt16(i * 4);
				left[offset + i] = (l < 32768 ? l : l - 65536) * (1.0 / 32768.0);
				var r = chunkBuf.getUInt16(i * 4 + 2);
				right[offset + i] = (r < 32768 ? r : r - 65536) * (1.0 / 32768.0);
			}
			offset += chunk;
		}
	}

	function getAudioInterleaved(output:haxe.io.Float32Array, numSamples:Int):Void {
		var offset = 0;
		while (offset < numSamples) {
			var chunk = numSamples - offset;
			if (chunk > CHUNK) chunk = CHUNK;
			C.get_audio(chunkBuf, chunk * 4);
			for (i in 0...chunk) {
				var l = chunkBuf.getUInt16(i * 4);
				output[(offset + i) * 2]     = (l < 32768 ? l : l - 65536) * (1.0 / 32768.0);
				var r = chunkBuf.getUInt16(i * 4 + 2);
				output[(offset + i) * 2 + 1] = (r < 32768 ? r : r - 65536) * (1.0 / 32768.0);
			}
			offset += chunk;
		}
	}
}
