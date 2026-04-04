package ibxm;

import haxe.io.Bytes;

/** A single note event within a pattern, containing pitch, instrument, volume and effect data. **/
@:publicFields
class Note {
	/** MIDI-style key index. 0 = no note, 1-117 = C0 to B9. **/
	var key:Int;

	/** 1-based instrument index. 0 = no instrument. **/
	var instrument:Int;

	/** Volume column value. 0xFF = no volume command. **/
	var volume:Int;

	/** Effect type identifier. **/
	var effect:Int;

	/** Effect parameter byte. **/
	var param:Int;

	private static final KEY_NAMES = "A-A#B-C-C#D-D#E-F-F#G-G#";
	private static final B36 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

	private static inline final MAX_NOTE_KEY = 118;
	private static inline final NO_VALUE = 0xFF;
	private static inline final NIBBLE_MASK = 0xF;
	private static inline final EXTENDED_EFFECT_MIN = 0x80;
	private static inline final EXTENDED_EFFECT_MAX = 0x9F;
	private static inline final ASCII_DASH = 45;
	private static inline final ASCII_ZERO = 48;
	private static inline final ASCII_BACKTICK = 96;
	private static inline final MAX_EFFECT = 36;

	function new(key:Int, instrument:Int, volume:Int, effect:Int, param:Int) {
		this.key = key;
		this.instrument = instrument;
		this.volume = volume;
		this.effect = effect;
		this.param = param;
	}

	/** Returns a compact string representation of the note, e.g. "C-501v40A04". **/
	function toChars():String {
		var buf = new StringBuf();

		// Note name (3 chars)
		if (key > 0 && key < MAX_NOTE_KEY) {
			var ki = ((key + 2) % 12) * 2;
			buf.addChar(KEY_NAMES.charCodeAt(ki));
			buf.addChar(KEY_NAMES.charCodeAt(ki + 1));
			buf.addChar(ASCII_ZERO + Std.int((key + 2) / 12));
		} else {
			buf.add("---");
		}

		// Instrument (2 chars)
		buf.addChar((instrument > NIBBLE_MASK && instrument < NO_VALUE) ? B36.charCodeAt((instrument >> 4) & NIBBLE_MASK) : ASCII_DASH);
		buf.addChar((instrument > 0x0 && instrument < NO_VALUE) ? B36.charCodeAt(instrument & NIBBLE_MASK) : ASCII_DASH);

		// Volume (2 chars)
		buf.addChar((volume > NIBBLE_MASK && volume < NO_VALUE) ? B36.charCodeAt((volume >> 4) & NIBBLE_MASK) : ASCII_DASH);
		buf.addChar((volume > 0x0 && volume < NO_VALUE) ? B36.charCodeAt(volume & NIBBLE_MASK) : ASCII_DASH);

		// Effect (3 chars)
		if ((effect > 0 || param > 0) && effect < MAX_EFFECT) {
			buf.addChar(B36.charCodeAt(effect));
		} else if (effect > EXTENDED_EFFECT_MIN && effect < EXTENDED_EFFECT_MAX) {
			buf.addChar(ASCII_BACKTICK + (effect & 0x1F));
		} else {
			buf.addChar(ASCII_DASH);
		}
		buf.addChar((effect > 0 || param > 0) ? B36.charCodeAt((param >> 4) & NIBBLE_MASK) : ASCII_DASH);
		buf.addChar((effect > 0 || param > 0) ? B36.charCodeAt(param & NIBBLE_MASK) : ASCII_DASH);

		return buf.toString();
	}
}

/** A pattern containing note data for all channels across a number of rows. **/
@:publicFields
class Pattern {
	/** Number of rows in this pattern. Varies per pattern in XM; fixed at 64 for MOD and S3M. **/
	var numRows:Int;

	/** Number of channels. Same as the module's channel count. **/
	var numChannels:Int;

	var data:Bytes;

	function new(numRows:Int, numChannels:Int, data:Bytes) {
		this.numRows = numRows;
		this.numChannels = numChannels;
		this.data = data;
	}

	static inline final BYTES_PER_NOTE = 5;

	/** Returns the note at the given row and channel. **/
	function getNote(row:Int, channel:Int):Note {
		var offset = (row * numChannels + channel) * BYTES_PER_NOTE;
		return new Note(data.get(offset), data.get(offset + 1), data.get(offset + 2), data.get(offset + 3), data.get(offset + 4));
	}
}
