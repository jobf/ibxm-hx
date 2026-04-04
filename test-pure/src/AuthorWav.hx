import audio.IAudioPlayer;
import audio.IReplaySource;
import haxe.io.Bytes;
import sys.io.File;
import format.wav.Data;
import format.wav.Writer;

class AuthorWav implements IAudioPlayer {
	public var isPlaying:Bool = false;
	public var samplesProcessed:Int = 0;

	final sampleRate:Int;
	final outputPath:String;
	final chunkSize = 4096;
	final bytesPerFrame = 4; // stereo Int16

	var source:IReplaySource;

	public function new(sampleRate:Int, outputPath:String) {
		this.sampleRate = sampleRate;
		this.outputPath = outputPath;
	}

	public function setAudioSource(s:IReplaySource) {
		source = s;
	}

	public function getSamplingRate():Float return sampleRate;
	public function getSamplesProcessed():Int return samplesProcessed;
	public function stop():Void {}
	public function pause():Void {}
	public function resume():Void {}

	public function play():Void {
		isPlaying = true;
		samplesProcessed = 0;

		var totalSamples = source.calculateSongDuration();
		var allAudio = Bytes.alloc(totalSamples * bytesPerFrame);
		var chunkBuf = Bytes.alloc(chunkSize * bytesPerFrame);

		var pos = 0;
		while (pos < totalSamples) {
			var count = Std.int(Math.min(chunkSize, totalSamples - pos));
			source.getAudio(chunkBuf, count * bytesPerFrame);
			allAudio.blit(pos * bytesPerFrame, chunkBuf, 0, count * bytesPerFrame);
			pos += count;
		}

		var out = File.write(outputPath, true);
		new Writer(out).write({
			header: {
				format: WF_PCM,
				channels: 2,
				samplingRate: sampleRate,
				byteRate: sampleRate * bytesPerFrame,
				blockAlign: bytesPerFrame,
				bitsPerSample: 16
			},
			data: allAudio,
			cuePoints: []
		});
		out.close();

		samplesProcessed = totalSamples;
		isPlaying = false;
	}
}
