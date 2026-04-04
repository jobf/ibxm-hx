package audio.lime;

import lime.media.openal.ALC;
import lime.media.openal.AL;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALSource;
import lime.utils.Int16Array;
import haxe.io.Bytes;
import haxe.Timer;
import ibxm.Replay;

@:publicFields
class AudioPlayer implements IAudioPlayer {
	var replay:IReplaySource;
	var buffers:Array<ALBuffer>;
	var source:ALSource;
	var timer:haxe.Timer;
	var buffersProcessed:Int = 0;

	var sampleRate:Int;
	var numChannels = 2;

	var bufferSize:Int;
	var bufferCount:Int;
	var totalSamples:Int = 0;
	var samplesProcessed:Int = 0;
	var isInitialized:Bool = false;
	var isPlaying:Bool = false;
	var sampleBuffer:Bytes;
	
	public function new(sampleRate:Int = 48000) {
		this.sampleRate = sampleRate;
	}

	function init():Void {
		bufferCount = 2;
		buffers = AL.genBuffers(bufferCount);
		// source will play the buffered audio
		source = AL.createSource();
		var bufferSampleCount = 2048;
		bufferSize = bufferSampleCount * numChannels * 2;
		// trace('bufferSampleCount $bufferSampleCount bufferSize $bufferSize');
		sampleBuffer = Bytes.alloc(bufferSize);
		sampleBuffer.fill(0, bufferSize, 0);

		var time = 1000 / 144; // the fastest it needs to go? e.g. if we want to drive it from a 144hz vsynced update loop)
		timer = new Timer(time);

		// trace('time $time');

		for (buffer in buffers) {
			AL.bufferData(buffer, AL.FORMAT_STEREO16, Int16Array.fromBytes(sampleBuffer), bufferSize, sampleRate);
			AL.sourceQueueBuffer(source, buffer);
			sampleBuffer.fill(0, bufferSize, 0);
		}

		timer.run = () -> {
			var num_buffers_finished:Int = AL.getSourcei(source, AL.BUFFERS_PROCESSED);
			buffersProcessed += num_buffers_finished;

			if (num_buffers_finished > 0) {
				// iterate the buffers that need to be refilled
				var finished_buffers = AL.sourceUnqueueBuffers(source, num_buffers_finished);
				for (buffer in finished_buffers) {
					if (isInitialized) {
						replay.getAudio(sampleBuffer, bufferSize);
					}
					AL.bufferData(buffer, AL.FORMAT_STEREO16, Int16Array.fromBytes(sampleBuffer), bufferSize, sampleRate);
					AL.sourceQueueBuffer(source, buffer);
					// sampleBuffer.fill(0, bufferSize, 0);
					samplesProcessed += bufferSampleCount;
				}
			}
		}
	}

	public function getSamplingRate():Float {
		return sampleRate;
	}

	public function getSamplesProcessed():Int {
		return samplesProcessed;
	}

	public function setAudioSource(replay:IReplaySource) {
		this.replay = replay;
		totalSamples = replay.calculateSongDuration();
		// trace('totalSamples $totalSamples');
		init();
		isInitialized = true;
	}

	// for debugging :sweat:
	// public function write(interleaved:Bytes, name:String) {
	// 	var bits_per_sample = 16;
	// 	var numchannels = 2;
	// 	var wav_file = WavFile.from_bytes(interleaved, Std.int(sampleRate), numchannels, bits_per_sample);
	// 	WavFile.write_to_disk(wav_file, name + ".wav");
	// }

	public function play() {
		AL.sourcePlay(source);
		isPlaying = true;
	}

	public function playModule(moduleBytes:Bytes) {
		Replay.initialise(moduleBytes, sampleRate);
		setAudioSource(Replay.getSource());
		AL.sourcePlay(source);
		isPlaying = true;
	}

	public function stop() {
		AL.sourceStop(source);
		
		samplesProcessed = 0;
		isPlaying = false;
	}

	public function pause() {
		if (!isPlaying) return;
        
		isPlaying = false;
		AL.sourcePause(source);
	}

	public function resume() {
		if(isPlaying) return;

		AL.sourcePlay(source);
		isPlaying = true;
	}
}
