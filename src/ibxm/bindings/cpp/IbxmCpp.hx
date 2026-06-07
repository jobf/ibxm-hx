package ibxm.bindings.cpp;

#if cpp
import haxe.io.Bytes;

@:buildXml('
<files id="haxe">
    <compilerflag value="-I${haxelib:ibxm-hx}/external/micromod/ibxm-ac"/>
    <compilerflag value="-I${haxelib:ibxm-hx}/glue"/>
    <file name="${haxelib:ibxm-hx}/external/micromod/ibxm-ac/ibxm.c"/>
    <file name="${haxelib:ibxm-hx}/glue/ibxmCpp.cpp"/>
</files>
')
@:include("ibxmCpp.h")
private extern class C {
	@:native("ibxm_cpp_get_version")
	static function get_version():cpp.ConstCharStar;

	@:native("ibxm_cpp_initialise")
	static function initialise(data:cpp.Pointer<cpp.UInt8>, file_length:Int, sample_rate:Int, interpolation:Int):Int;

	@:native("ibxm_cpp_get_name")
	static function get_name():cpp.ConstCharStar;

	@:native("ibxm_cpp_get_instrument")
	static function get_instrument(instrument:Int):cpp.ConstCharStar;

	@:native("ibxm_cpp_get_song_duration")
	static function get_song_duration():Int;

	@:native("ibxm_cpp_get_audio")
	static function get_audio(output_buffer:cpp.Pointer<cpp.UInt8>, len:Int):Void;

	@:native("ibxm_cpp_set_position")
	static function set_position(pos:Int):Void;

	@:native("ibxm_cpp_seek")
	static function seek(sample_pos:Int):Int;

	@:native("ibxm_cpp_calculate_mix_buf_len")
	static function calculate_mix_buf_len(sample_rate:Int):Int;

	@:native("ibxm_cpp_set_muted")
	static function set_muted(channel:Int, muted:Bool):Void;

	@:native("ibxm_cpp_is_muted")
	static function is_muted(channel:Int):Bool;

	@:native("ibxm_cpp_get_num_patterns")
	static function get_num_patterns():Int;

	@:native("ibxm_cpp_get_sequence")
	static function get_sequence(output:cpp.Pointer<cpp.UInt8>):Void;

	@:native("ibxm_cpp_get_instrument_data")
	static function get_instrument_data(index:Int, output:cpp.Pointer<cpp.UInt8>):Void;

	@:native("ibxm_cpp_get_sample_data")
	static function get_sample_data(instrument:Int, sample:Int, output:cpp.Pointer<cpp.UInt8>):Void;

	@:native("ibxm_cpp_get_num_channels")
	static function get_num_channels():Int;

	@:native("ibxm_cpp_get_num_instruments")
	static function get_num_instruments():Int;

	@:native("ibxm_cpp_get_sequence_length")
	static function get_sequence_length():Int;

	@:native("ibxm_cpp_get_sequence_pos")
	static function get_sequence_pos():Int;

	@:native("ibxm_cpp_get_row")
	static function get_row():Int;

	@:native("ibxm_cpp_get_pattern_num_rows")
	static function get_pattern_num_rows(seqPos:Int):Int;

	@:native("ibxm_cpp_get_pattern_data")
	static function get_pattern_data(seqPos:Int, output:cpp.Pointer<cpp.UInt8>):Void;
}

@:publicFields
class IbxmCpp {
	static function getVersion():String {
		return C.get_version();
	}

	static function initialise(module:haxe.io.Bytes, sampleRate:Int, interpolation:Bool):Int {
		var ptr = cpp.NativeArray.address(module.getData(), 0);
		return C.initialise(ptr, module.length, sampleRate, interpolation ? 1 : 0);
	}

	static function getName():String {
		return C.get_name();
	}

	static function getInstrumentName(instrument:Int):String {
		return C.get_instrument(instrument);
	}

	static function getSongDuration():Int {
		return C.get_song_duration();
	}

	static function setPosition(pos:Int):Void {
		C.set_position(pos);
	}

	static function seek(samplePosition:Int):Int {
		return C.seek(samplePosition);
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
		C.get_sequence(cpp.NativeArray.address(buf.getData(), 0));
		return [for (i in 0...len) buf.getInt32(i * 4)];
	}

	static inline final STRUCT_BUFFER_SIZE = 56;

	static function getInstrument(index:Int):ibxm.Instrument {
		var buf = haxe.io.Bytes.alloc(STRUCT_BUFFER_SIZE);
		C.get_instrument_data(index, cpp.NativeArray.address(buf.getData(), 0));
		return ibxm.Instrument.fromBytes(buf);
	}

	static function getSample(instrument:Int, sample:Int):ibxm.Sample {
		var buf = haxe.io.Bytes.alloc(STRUCT_BUFFER_SIZE);
		C.get_sample_data(instrument, sample, cpp.NativeArray.address(buf.getData(), 0));
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
		C.get_pattern_data(seqPos, cpp.NativeArray.address(buf.getData(), 0));
		return buf;
	}

	static function getSource():IbxmSource {
		return new IbxmSource();
	}
}

@:publicFields
class IbxmSource {
	static inline final CHUNK = 2048;
	final chunkBuf = haxe.io.Bytes.alloc(CHUNK * 4);

	function new() {}

	function getAudio(left:haxe.io.Float32Array, right:haxe.io.Float32Array, numSamples:Int):Void {
		var offset = 0;
		while (offset < numSamples) {
			var chunk = numSamples - offset;
			if (chunk > CHUNK) chunk = CHUNK;
			C.get_audio(cpp.NativeArray.address(chunkBuf.getData(), 0), chunk * 4);
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
			C.get_audio(cpp.NativeArray.address(chunkBuf.getData(), 0), chunk * 4);
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
#end