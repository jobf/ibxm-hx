package ibxm;

import haxe.io.Bytes;
import juice.AudioDriverContract;
import ibxm.Pattern;
import ibxm.Instrument;
import ibxm.Sample;
import juice.SampleSource;
#if hl
import ibxm.bindings.hl.IbxmHl.IbxmHl as Ibxm;
import ibxm.bindings.hl.IbxmHl.IbxmSource;
#elseif cpp
import ibxm.bindings.cpp.IbxmCpp.IbxmCpp as Ibxm;
import ibxm.bindings.cpp.IbxmCpp.IbxmSource;
#else
import ibxm.bindings.js.IbxmJs.IbxmJs as Ibxm;
import ibxm.bindings.js.IbxmJs.IbxmSource;
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

	/** Parses the module data. Call `init` afterwards to complete initialisation.
		Returns an empty string on success, or an error message on failure. **/
	static function loadModule(moduleData:ModuleFormat):String {
		var error = "";
		try {
			var result = Ibxm.loadModule(moduleData);
			if (result != 0) {
				error = 'Module load failed.';
			}
		} 
		catch (e) {
			error = e.message;
		}
		return error;
	}

	/** Creates the replay engine at the given sample rate. Requires `loadModule` to have succeeded.
		Returns an empty string on success, or an error message on failure. **/
	static function init(sampleRate:Int, interpolation:Bool = true):String {
		var error = "";
		try {
			var result = Ibxm.init(sampleRate, interpolation);
			if (result != 0) {
				error = 'Replay creation failed.';
			}
			isInitialised = true;
		}
		catch (e) {
			error = e.message;
		}
		return error;
	}

	/** Returns the name string for the given instrument index. **/
	static function getInstrumentName(instrument:Int):String {
		return Ibxm.getInstrumentName(instrument);
	}

	/** Returns the total song duration in samples at the initialised sample rate. **/
	static function getSongDuration():Int {
		return Ibxm.getSongDuration();
	}

	/** Returns the ibxm library version string. **/
	static function getVersion():String {
		return Ibxm.getVersion();
	}

	/** Jumps to the given position in the sequence order list. **/
	static function setPosition(pattern:Int) {
		Ibxm.setPosition(pattern);
	}

	/** Seeks to approximately the given sample position. Returns the actual position reached. **/
	static function seek(samplePosition:Int):Int {
		return Ibxm.seek(samplePosition);
	}

	/** Returns the module name. **/
	static function getName():String {
		return Ibxm.getName();
	}

	/** Returns an ISampleSource wrapping the current replayer, for use with AudioDriver. **/
	static function getSource():ISampleSource {
		return new SampleSource(Ibxm.getSource());
	}

	/** Returns the number of channels in the loaded module. **/
	static function getNumChannels():Int {
		return Ibxm.getNumChannels();
	}

	/** Returns the number of instruments in the loaded module. **/
	static function getNumInstruments():Int {
		return Ibxm.getNumInstruments();
	}

	/** Returns the number of entries in the sequence/order list. **/
	static function getSequenceLength():Int {
		return Ibxm.getSequenceLength();
	}

	/** Returns the current playback position in the sequence order list. **/
	static function getSequencePos():Int {
		return Ibxm.getSequencePos();
	}

	/** Returns the current row being played. **/
	static function getRow():Int {
		return Ibxm.getRow();
	}

	/** Returns the number of rows in the pattern at the given sequence position. **/
	static function getPatternNumRows(seqPos:Int):Int {
		return Ibxm.getPatternNumRows(seqPos);
	}

	/** Mutes or unmutes the given channel. **/
	static function setMuted(channel:Int, muted:Bool):Void {
		Ibxm.setMuted(channel, muted);
	}

	/** Returns true if the given channel is muted. **/
	static function isMuted(channel:Int):Bool {
		return Ibxm.isMuted(channel);
	}

	/** Returns the number of unique patterns in the loaded module. **/
	static function getNumPatterns():Int {
		return Ibxm.getNumPatterns();
	}

	/** Returns the sequence order list as an array of pattern indices. **/
	static function getSequence():Array<Int> {
		return Ibxm.getSequence();
	}

	/** Returns the Instrument at the given index. **/
	static function getInstrument(index:Int):Instrument {
		return Ibxm.getInstrument(index);
	}

	/** Returns the Sample at the given instrument and sample index. **/
	static function getSample(instrument:Int, sample:Int):Sample {
		return Ibxm.getSample(instrument, sample);
	}

	/** Returns the pattern data at the given sequence position as a Pattern object. **/
	static function getPatternData(seqPos:Int):Pattern {
		var numRows = Ibxm.getPatternNumRows(seqPos);
		var numChannels = Ibxm.getNumChannels();
		return new Pattern(numRows, numChannels, Ibxm.getPatternData(seqPos));
	}
}
