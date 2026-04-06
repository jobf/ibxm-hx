package audio.lime;

import lime.utils.ArrayBufferView;
import lime.utils.ArrayBuffer;
import lime.media.openal.AL;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALSource;
import haxe.io.Float32Array;
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
	var interleavedBuf:Float32Array;

	public function new(sampleRate:Int = 48000) {
		this.sampleRate = sampleRate;
	}

	function init():Void {
		bufferCount = 2;
		buffers = AL.genBuffers(bufferCount);
		source = AL.createSource();
		
		#if (lime < "8.4.0")
		/* 
			disable hrtf to improve sound quality
			see https://github.com/openfl/lime/pull/2001
		*/
		if (AL.isExtensionPresent("AL_SOFT_direct_channels") && AL.isExtensionPresent("AL_SOFT_direct_channels_remix")) {
			static var DIRECT_CHANNELS_SOFT = 0x1033;
			static var REMIX_UNMATCHED_SOFT = 0x0002;
			AL.sourcei(source, DIRECT_CHANNELS_SOFT, REMIX_UNMATCHED_SOFT);
		}
		#end

		var bufferSampleCount = 2048;
		bufferSize = bufferSampleCount * numChannels * 4;
		var bufferArraySize = Std.int(bufferSampleCount * 2);
		interleavedBuf = new Float32Array(bufferArraySize);
		var interleavedView:lime.utils.Float32Array = lime.utils.Float32Array.fromBytes(interleavedBuf.view.buffer);
		var time = 1000 / 144;
		timer = new Timer(time);

		static var AL_FORMAT_STEREO_FLOAT32 = 0x10011;
		for (buffer in buffers) {
			AL.bufferData(buffer, AL_FORMAT_STEREO_FLOAT32, interleavedView, bufferSize, sampleRate);
			AL.sourceQueueBuffer(source, buffer);
		}

		timer.run = () -> {
			var num_buffers_finished:Int = AL.getSourcei(source, AL.BUFFERS_PROCESSED);
			buffersProcessed += num_buffers_finished;

			if (num_buffers_finished > 0) {
				var finished_buffers = AL.sourceUnqueueBuffers(source, num_buffers_finished);
				for (buffer in finished_buffers) {
					if (isInitialized) {
						replay.getAudioInterleaved(interleavedBuf, bufferSampleCount);
					}
					AL.bufferData(buffer, AL_FORMAT_STEREO_FLOAT32, interleavedView, bufferSize, sampleRate);
					AL.sourceQueueBuffer(source, buffer);
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
		init();
		isInitialized = true;
	}

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
