import ibxm.Replay;
import sys.io.File;

var SAMPLE_RATE = 48000;
var OUTPUT = "output.wav";

function main() {
	var args = Sys.args();
	if (args.length == 0) {
		trace("Usage: main <module.xm>");
		return;
	}
	var data = File.getBytes(args[0]);
	var err = Replay.initialise(data, SAMPLE_RATE);
	if (err != "") {
		trace('Error: $err');
		return;
	}

	trace('${Replay.getName()} — ${Replay.getNumChannels()} channels');

	var author = new AuthorWav(SAMPLE_RATE, OUTPUT, Replay.getSongDuration());
	author.setAudioSource(Replay.getSource());
	author.play();

	trace('Written $OUTPUT (${Std.int(author.samplesProcessed / SAMPLE_RATE)}s)');
}
