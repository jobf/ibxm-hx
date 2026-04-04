import audio.IAudioPlayer;
import audio.IReplaySource;
import haxe.io.Float32Array;
import haxe.io.BytesOutput;
import format.wav.Data;
import format.wav.Writer;

class AuthorWavJs implements IAudioPlayer {
	public var isPlaying:Bool = false;
	public var samplesProcessed:Int = 0;

	final sampleRate:Int;
	static final maxInt32 = 2147483647;

	var source:IReplaySource;

	public function new(sampleRate:Int) {
		this.sampleRate = sampleRate;
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
		var left = new Float32Array(totalSamples);
		var right = new Float32Array(totalSamples);
		source.getAudio(left, right, totalSamples);

		final channels = 2;
		final int32Size = 4;
		final bytesPerFrame = channels * int32Size;
		var pcmOut = new BytesOutput();
		pcmOut.bigEndian = false;
		for (i in 0...totalSamples) {
			pcmOut.writeInt32(Std.int(left[i] * maxInt32));
			pcmOut.writeInt32(Std.int(right[i] * maxInt32));
		}

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
		var blob = new js.html.Blob([wavBytes.getData()], {type: "audio/wav"});
		var url = js.html.URL.createObjectURL(blob);
		var a = cast(js.Browser.document.createElement("a"), js.html.AnchorElement);
		a.href = url;
		a.download = 'output.wav';
		a.click();
		js.html.URL.revokeObjectURL(url);

		samplesProcessed = totalSamples;
		isPlaying = false;
	}
}
