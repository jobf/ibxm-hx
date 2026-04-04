package ibxm.bindings.js;

import audio.IReplaySource;
import haxe.io.Float32Array;

@:native("IBXMModule") extern class Module {
	function new(data:js.lib.Int8Array):Void;
	var songName(default, null):String;
	var numPatterns(default, null):Int;
	var sequenceLength(default, null):Int;
	var sequence(default, null):js.lib.Int32Array;
	var numChannels(default, null):Int;
	var patterns(default, null):Array<JsPattern>;
	var instruments(default, null):Array<JsInstrument>;
}

@:native("IBXMInstrument") extern class JsInstrument {
	var name(default, null):String;
	var numSamples(default, null):Int;
	var volumeFadeOut(default, null):Int;
	var vibratoType(default, null):Int;
	var vibratoSweep(default, null):Int;
	var vibratoDepth(default, null):Int;
	var vibratoRate(default, null):Int;
	var samples(default, null):Array<JsSample>;
}

@:native("IBXMSample") extern class JsSample {
	var name(default, null):String;
	var loopStart(default, null):Int;
	var loopLength(default, null):Int;
	var volume(default, null):Int;
	var panning(default, null):Int;
	var relNote(default, null):Int;
	var fineTune(default, null):Int;
}

@:native("IBXMPattern") extern class JsPattern {
	var numRows(default, null):Int;
	function getNote(index:Int, note:IBXMNote):IBXMNote;
}

@:native("IBXMNote") extern class IBXMNote {
	function new():Void;
	var key:Int;
	var instrument:Int;
	var volume:Int;
	var effect:Int;
	var param:Int;
}

@:native("IBXMReplay") extern class Ibxm {
	function new(module:Module, sampleRate:Int):Void;
	function getVersion():String;
	function setInterpolation(isEnabled:Bool):Void;
	function getRow():Int;
	function getSequencePos():Int;
	function calculateSongDuration():Int;
	function calculateTickLen(tempo:Int, sampleRate:Int):Int;
	function setPosition(pattern:Int):Int;
	function seek(samplePos:Int):Int;
	function isMuted(channel:Int):Bool;
	function setMuted(channel:Int, mute:Bool):Void;
	function getAudio(leftBuf:Float32Array, rightBuf:Float32Array, count:Int):Void;
}

@:publicFields
class IbxmJs {
	private static var ibxm:Ibxm;
	private static var module:Module;

	// the minimum tempo a module can be
	static inline final MIN_TEMPO = 32;
	// highest feasible sample rate
	static inline final MAX_SAMPLE_RATE = 128000;
	// internal resample padding (IBXM.js line 147)
	static inline final RESAMPLE_PADDING = 65;
	// 2 x oversample * 2 channels
	static inline final MIX_BUFFER_STRIDE = 4;

	static function initialise(data:js.lib.Int8Array, sampling_rate:Int) {
		module = new Module(data);
		ibxm = new Ibxm(module, sampling_rate);
	}

	static function get_instrument_name(instrument:Int):String {
		return module.instruments[instrument]?.name ?? "";
	}

	static function calculate_song_duration():Int {
		return ibxm.calculateSongDuration();
	}

	static function calculate_mix_buffer_len(sample_rate:Int):Int {
		// this returns the largest potentially needed buffersize, it's a bit crude but it not going to cause problems
		return (ibxm.calculateTickLen(MIN_TEMPO, MAX_SAMPLE_RATE) + RESAMPLE_PADDING) * MIX_BUFFER_STRIDE;
	}

	static function get_version():String {
		return ibxm.getVersion();
	}

	static function set_position(pattern:Int) {
		ibxm.setPosition(pattern);
	}

	static function seek(samplePosition:Int) {
		ibxm.seek(samplePosition);
	}

	static function get_name():String {
		return module.songName;
	}

	static function get_num_channels():Int {
		return module.numChannels;
	}

	static function get_num_instruments():Int {
		return module.instruments.length - 1;
	}

	static function get_sequence_length():Int {
		return module.sequenceLength;
	}

	static function get_num_patterns():Int {
		return module.numPatterns;
	}

	static function get_sequence():Array<Int> {
		return [for (i in 0...module.sequenceLength) module.sequence[i]];
	}

	static function get_sequence_pos():Int {
		return ibxm.getSequencePos();
	}

	static function get_row():Int {
		return ibxm.getRow();
	}

	static function get_pattern_num_rows(seqPos:Int):Int {
		var pat = module.sequence[seqPos];
		return module.patterns[pat].numRows;
	}

	static function get_pattern_data(seqPos:Int):haxe.io.Bytes {
		var numChannels = get_num_channels();
		var numRows = get_pattern_num_rows(seqPos);
		var pat = module.sequence[seqPos];
		var buf = haxe.io.Bytes.alloc(numChannels * numRows * 5);
		var pattern = module.patterns[pat];
		var note = new IBXMNote();
		for (r in 0...numRows) {
			for (c in 0...numChannels) {
				pattern.getNote(r * numChannels + c, note);
				var offset = (r * numChannels + c) * 5;
				buf.set(offset, note.key);
				buf.set(offset + 1, note.instrument);
				buf.set(offset + 2, note.volume);
				buf.set(offset + 3, note.effect);
				buf.set(offset + 4, note.param);
			}
		}
		return buf;
	}

	static function get_instrument(index:Int):ibxm.Instrument {
		var ins = module.instruments[index];
		return new ibxm.Instrument(ins.name, ins.numSamples, ins.volumeFadeOut, ins.vibratoType, ins.vibratoSweep, ins.vibratoDepth, ins.vibratoRate);
	}

	static function get_sample(instrument:Int, sample:Int):ibxm.Sample {
		var s = module.instruments[instrument].samples[sample];
		return new ibxm.Sample(s.name, s.loopStart, s.loopLength, s.volume, s.panning, // JS already uses -1 for unset, 0-255 for value
			s.relNote, s.fineTune);
	}

	static function set_muted(channel:Int, muted:Bool):Void {
		ibxm.setMuted(channel, muted);
	}

	static function is_muted(channel:Int):Bool {
		return ibxm.isMuted(channel);
	}

	static function get_source():IReplaySource {
		return new IbxmSource(ibxm);
	}
}

@:publicFields
class IbxmSource implements IReplaySource {
	var replay:Ibxm;

	function new(replay:Ibxm) {
		this.replay = replay;
	}

	function calculateSongDuration():Int {
		return replay.calculateSongDuration();
	}

	function calculateMixBufferLen(sampleRate:Int):Int {
		return IbxmJs.calculate_mix_buffer_len(sampleRate);
	}

	function getAudio(leftBuf:Float32Array, rightBuf:Float32Array, count:Int):Void {
		replay.getAudio(leftBuf, rightBuf, count);
	}
}
