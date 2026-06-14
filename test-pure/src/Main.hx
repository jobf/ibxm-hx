import sys.io.File;
import ibxm.Replay;
import juice.driver.format.AudioDriver;

var SAMPLE_RATE = 48000;
var OUTPUT = "output.wav";

function main() {
	var args = Sys.args();
	if (args.length == 0) {
		trace("Usage: main <module.xm>");
		return;
	}
	var data = File.getBytes(args[0]);
	var error = Replay.loadModule(data);
	if (error == "") error = Replay.init(SAMPLE_RATE);
	if (error != "") {
		trace('Error: $error');
		return;
	}

	trace('${Replay.getName()} — ${Replay.getNumChannels()} channels');

	var author = new AudioDriver(Replay.getSongDuration(), OUTPUT);
	author.setSampleStream(Replay.getStream());
	author.play();

	trace('Written $OUTPUT (${Std.int(author.samplesProcessed / SAMPLE_RATE)}s)');
}
