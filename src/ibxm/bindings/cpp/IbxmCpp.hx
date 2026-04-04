package ibxm.bindings.cpp;

import haxe.io.Bytes;
import audio.IReplaySource;

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

	@:native("ibxm_cpp_calculate_song_duration")
	static function calculate_song_duration():Int;

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
	static function get_version():String {
		return C.get_version();
	}

	static function initialise(module:haxe.io.Bytes, sampleRate:Int):Int {
		var ptr = cpp.NativeArray.address(module.getData(), 0);
		return C.initialise(ptr, module.length, sampleRate, 0);
	}

	static function get_name():String {
		return C.get_name();
	}

	static function get_instrument_name(instrument:Int):String {
		return C.get_instrument(instrument);
	}

	static function calculate_song_duration():Int {
		return C.calculate_song_duration();
	}

	static function get_audio(output_buffer:haxe.io.Bytes, len:Int):Void {
		var ptr = cpp.NativeArray.address(output_buffer.getData(), 0);
		C.get_audio(ptr, len);
	}

	static function set_position(pos:Int):Void {
		C.set_position(pos);
	}

	static function seek(samplePosition:Int):Int {
		return C.seek(samplePosition);
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
		C.get_sequence(cpp.NativeArray.address(buf.getData(), 0));
		return [for (i in 0...len) buf.getInt32(i * 4)];
	}

	static inline final STRUCT_BUFFER_SIZE = 56;

	static function get_instrument(index:Int):ibxm.Instrument {
		var buf = haxe.io.Bytes.alloc(STRUCT_BUFFER_SIZE);
		C.get_instrument_data(index, cpp.NativeArray.address(buf.getData(), 0));
		return ibxm.Instrument.fromBytes(buf);
	}

	static function get_sample(instrument:Int, sample:Int):ibxm.Sample {
		var buf = haxe.io.Bytes.alloc(STRUCT_BUFFER_SIZE);
		C.get_sample_data(instrument, sample, cpp.NativeArray.address(buf.getData(), 0));
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
		C.get_pattern_data(seqPos, cpp.NativeArray.address(buf.getData(), 0));
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
		return IbxmCpp.calculate_song_duration();
	}

	function calculateMixBufferLen(sampleRate:Int):Int {
		return IbxmCpp.calculate_mix_buffer_len(sampleRate);
	}

	function getAudio(interleavedBuf:Bytes, count:Int):Void {
		get_audio(interleavedBuf, count);
	}
}
