package ibxm;

import haxe.io.Bytes;
import audio.IAudioPlayer;
import ibxm.Pattern;
import ibxm.Instrument;
import ibxm.Sample;

#if hl
import ibxm.bindings.hl.IbxmHl as Ibxm;
#end

#if cpp
import ibxm.bindings.cpp.IbxmCpp as Ibxm;
#end

#if js
import ibxm.bindings.js.IbxmJs as Ibxm;
#end


#if js
typedef ModuleFormat = js.lib.Int8Array;
#else
typedef ModuleFormat = haxe.io.Bytes;
#end


/** Static facade over the platform-specific ibxm bindings.
	All playback, query, and module inspection functions are accessed through here. **/
@:publicFields
class Replay {
	/** True once `initialise` has completed successfully. **/
	static var isInitialised:Bool = false;

	#if sys
	private static function readFile(path:String, to:Bytes, length:Int):Int {
		var count = -1;
		var file = sys.io.File.read(path);
		var pos = 0;
		count = file.readBytes(to, pos, length);
		file.close();
		return count;
	}

	/** Reads a module file from disk into a Bytes buffer. **/
	static function readModule(path:String, length:Int):Bytes {
		var module:Bytes = Bytes.alloc(length);
		var len = readFile(path, module, length);
		return module;
	}
	#end

	/** Initialises the replayer with the given module data and sample rate.
		Returns an empty string on success, or an error message on failure. **/
	static function initialise(module_data:ModuleFormat, sample_rate:Int):String {
		if (sample_rate <= 0) {
			return 'Invalid sample rate $sample_rate. Cannot continue.';
		}

		var errorMessage = "";

		try {
			Ibxm.initialise(module_data, sample_rate);
			isInitialised = true;
		} catch (e) {
			isInitialised = false;
			errorMessage = e.message;
		}

		return errorMessage;
	}

	/** Returns the name string for the given instrument index. **/
	static function getInstrumentName(instrument:Int):String {
		return Ibxm.get_instrument_name(instrument);
	}

	/** Returns the total song duration in samples. **/
	static function calculateSongDuration():Int {
		return Ibxm.calculate_song_duration();
	}

	/** Returns the ibxm library version string. **/
	static function getVersion():String {
		return Ibxm.get_version();
	}

	/** Jumps to the given position in the sequence order list. **/
	static function setPosition(pattern:Int) {
		Ibxm.set_position(pattern);
	}

	/** Seeks to approximately the given sample position. Returns the actual position reached. **/
	static function seek(samplePosition:Int) {
		Ibxm.seek(samplePosition);
	}

	/** Returns the module name. **/
	static function getName():String {
		return Ibxm.get_name();
	}

	/** Returns an IReplaySource wrapping the current replayer, for use with AudioPlayer. **/
	static function getSource() {
		return Ibxm.get_source();
	}

	/** Returns the number of channels in the loaded module. **/
	static function getNumChannels():Int {
		return Ibxm.get_num_channels();
	}

	/** Returns the number of instruments in the loaded module. **/
	static function getNumInstruments():Int {
		return Ibxm.get_num_instruments();
	}

	/** Returns the number of entries in the sequence/order list. **/
	static function getSequenceLength():Int {
		return Ibxm.get_sequence_length();
	}

	/** Returns the current playback position in the sequence order list. **/
	static function getSequencePos():Int {
		return Ibxm.get_sequence_pos();
	}

	/** Returns the current row being played. **/
	static function getRow():Int {
		return Ibxm.get_row();
	}

	/** Returns the number of rows in the pattern at the given sequence position. **/
	static function getPatternNumRows(seqPos:Int):Int {
		return Ibxm.get_pattern_num_rows(seqPos);
	}

	/** Mutes or unmutes the given channel. **/
	static function setMuted(channel:Int, muted:Bool):Void {
		Ibxm.set_muted(channel, muted);
	}

	/** Returns true if the given channel is muted. **/
	static function isMuted(channel:Int):Bool {
		return Ibxm.is_muted(channel);
	}

	/** Returns the number of unique patterns in the loaded module. **/
	static function getNumPatterns():Int {
		return Ibxm.get_num_patterns();
	}

	/** Returns the sequence order list as an array of pattern indices. **/
	static function getSequence():Array<Int> {
		return Ibxm.get_sequence();
	}

	/** Returns the Instrument at the given index. **/
	static function getInstrument(index:Int):Instrument {
		return Ibxm.get_instrument(index);
	}

	/** Returns the Sample at the given instrument and sample index. **/
	static function getSample(instrument:Int, sample:Int):Sample {
		return Ibxm.get_sample(instrument, sample);
	}

	/** Returns the pattern data at the given sequence position as a Pattern object. **/
	static function getPatternData(seqPos:Int):Pattern {
		var numRows = Ibxm.get_pattern_num_rows(seqPos);
		var numChannels = Ibxm.get_num_channels();
		return new Pattern(numRows, numChannels, Ibxm.get_pattern_data(seqPos));
	}
}
