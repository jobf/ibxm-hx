import audio.IAudioPlayer;
import audio.IReplaySource;
import haxe.io.Float32Array;
import haxe.io.BytesOutput;
import format.wav.Data;
import format.wav.Writer;

class AuthorWav implements IAudioPlayer {
	public var isPlaying:Bool = false;
	public var samplesProcessed:Int = 0;

	final sampleRate:Int;

	#if sys
	final outputPath:String;

	public function new(sampleRate:Int, outputPath:String) {
		this.sampleRate = sampleRate;
		this.outputPath = outputPath;
	}
	#else
	public function new(sampleRate:Int) {
		this.sampleRate = sampleRate;
	}
	#end

	var source:IReplaySource;

	public function setAudioSource(s:IReplaySource)
		source = s;

	public function getSamplingRate():Float
		return sampleRate;

	public function getSamplesProcessed():Int
		return samplesProcessed;

	public function stop():Void {}

	public function pause():Void {}

	public function resume():Void {}

	public function play():Void {
		isPlaying = true;
		samplesProcessed = 0;

		var totalSamples = source.calculateSongDuration();

		final channels = 2;
		final bytesPerFrame = channels * 4;
		var pcmOut = new BytesOutput();
		pcmOut.bigEndian = false;
		#if js
		/*
			web audio uses separate left and right 
			so excercise ReplaySource.getAudio
		 */
		var left = new Float32Array(totalSamples);
		var right = new Float32Array(totalSamples);
		source.getAudio(left, right, totalSamples);
		for (i in 0...totalSamples) {
			pcmOut.writeInt32(Std.int(left[i] * 0x7FFFFFFF));
			pcmOut.writeInt32(Std.int(right[i] * 0x7FFFFFFF));
		}
		#else
		/*
			excercise ReplaySource.getAudioInterleaved
		 */
		var interleaved = new Float32Array(totalSamples * 2);
		source.getAudioInterleaved(interleaved, totalSamples);
		for (i in 0...totalSamples * 2) {
			pcmOut.writeInt32(Std.int(interleaved[i] * 0x7FFFFFFF));
		}
		#end

		var wavOut = new BytesOutput();
		new Writer(wavOut).write({
			header: {
				format: WF_PCM,
				channels: channels,
				samplingRate: sampleRate,
				byteRate: sampleRate * bytesPerFrame,
				blockAlign: bytesPerFrame,
				bitsPerSample: 32
			},
			data: pcmOut.getBytes(),
			cuePoints: []
		});
		var wavBytes = wavOut.getBytes();

		#if js
		var blob = new js.html.Blob([wavBytes.getData()], {type: "audio/wav"});
		var url = js.html.URL.createObjectURL(blob);
		var a = cast(js.Browser.document.createElement("a"), js.html.AnchorElement);
		a.href = url;
		a.download = 'output.wav';
		a.click();
		js.html.URL.revokeObjectURL(url);
		#else
		var out = sys.io.File.write(outputPath, true);
		out.write(wavBytes);
		out.close();
		#end

		samplesProcessed = totalSamples;
		isPlaying = false;
	}
}
