package ibxm;

import haxe.io.Bytes;

/** Sample data associated with an instrument.
	Each instrument can have multiple samples mapped across different note ranges (XM only).
	MOD and S3M instruments always have a single sample. **/
@:publicFields
class Sample {
	var name:String;

	/** Start position of the loop in samples. **/
	var loopStart:Int;

	/** Length of the loop in samples. 0 means no loop. **/
	var loopLength:Int;

	/** Sample volume, 0-64. **/
	var volume:Int;

	/** Panning position. -1 = unset (use channel default), 0-255 = left to right. **/
	var panning:Int;

	/** Relative note offset applied to this sample (XM only). **/
	var relNote:Int;

	/** Fine-tune value in 1/128 semitone units (XM only). **/
	var fineTune:Int;

	function new(name, loopStart, loopLength, volume, panning, relNote, fineTune) {
		this.name = name;
		this.loopStart = loopStart;
		this.loopLength = loopLength;
		this.volume = volume;
		this.panning = panning;
		this.relNote = relNote;
		this.fineTune = fineTune;
	}

	static inline final NAME_SIZE = 32;
	static inline final FIELD_STRIDE = 4;

	static function fromBytes(b:Bytes):Sample {
		var name = "";
		for (i in 0...NAME_SIZE) {
			var c = b.get(i);
			if (c == 0) break;
			name += String.fromCharCode(c);
		}
		return new Sample(
			name,
			b.getInt32(NAME_SIZE),
			b.getInt32(NAME_SIZE + FIELD_STRIDE),
			b.getInt32(NAME_SIZE + FIELD_STRIDE * 2),
			b.getInt32(NAME_SIZE + FIELD_STRIDE * 3),
			b.getInt32(NAME_SIZE + FIELD_STRIDE * 4),
			b.getInt32(NAME_SIZE + FIELD_STRIDE * 5)
		);
	}
}
