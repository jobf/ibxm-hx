package ibxm;

import haxe.io.Bytes;

/** Instrument metadata loaded from a module file.
	XM specific fields are 0 for MOD and S3M files. **/
@:publicFields
class Instrument {
	var name:String;

	/** Number of samples in this instrument. MOD instruments always have 1. **/
	var numSamples:Int;

	/** Volume fadeout rate (XM only). 0–65535. Decremented each tick after note release. **/
	var volFadeout:Int;

	/** Vibrato type (XM only). 0=sine, 1=ramp down, 2=square, 3=random. **/
	var vibType:Int;

	/** Vibrato sweep (XM only). 0–255 ticks to ramp up to full vibrato depth. **/
	var vibSweep:Int;

	/** Vibrato depth (XM only). 0–15, where 15 ≈ 1 semitone. **/
	var vibDepth:Int;

	/** Vibrato rate (XM only). 0–63, higher = faster oscillation. **/
	var vibRate:Int;

	function new(name, numSamples, volFadeout, vibType, vibSweep, vibDepth, vibRate) {
		this.name = name;
		this.numSamples = numSamples;
		this.volFadeout = volFadeout;
		this.vibType = vibType;
		this.vibSweep = vibSweep;
		this.vibDepth = vibDepth;
		this.vibRate = vibRate;
	}

	static inline final NAME_SIZE = 32;
	static inline final FIELD_STRIDE = 4;

	static function fromBytes(b:Bytes):Instrument {
		var name = "";
		for (i in 0...NAME_SIZE) {
			var c = b.get(i);
			if (c == 0)
				break;
			name += String.fromCharCode(c);
		}
		return new Instrument(
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
