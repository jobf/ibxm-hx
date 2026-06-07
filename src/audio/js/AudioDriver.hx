package audio.js;

import js.lib.Int8Array;
import haxe.io.Bytes;
import haxe.io.Float32Array;
import audio.IAudioSource;
import audio.IAudioDriver;
import audio.js.AudioWorkletContext;
import js.html.Blob;
import js.html.URL;
import ibxm.bindings.js.IbxmJs as Replay;

@:publicFields
class AudioDriver implements IAudioDriver {
	private var audioSource:IAudioSource;
	private var audioContext:AudioWorkletContext;
	private var node:AudioWorkletNode;

	private var bufferSize:Int = 1024;
	private var isInitialized:Bool = false;
	private var moduleReady:js.lib.Promise<Void>;
	
	var isPlaying:Bool = false;
	var samplesProcessed:Int = 0;

	function new():Void {
		audioContext = new AudioWorkletContext();

		var blob = new Blob([Processor.code], {type: "application/javascript"});
		var url = URL.createObjectURL(blob);
		moduleReady = audioContext.audioWorklet.addModule(url);
	}

	function initAudioWorkletNode() {
		// create the AudioWorkletNode
		node = new AudioWorkletNode(audioContext, 'audio-stream-processor', {
			// numberOfInputs: numberOfInputs,
			numberOfOutputs: 1,
			outputChannelCount: [2],
			// parameterData: parameterData,
			// processorOptions: processorOptions,
			// channelCount: channelCount,
			// channelCountMode: channelCountMode,
			// channelInterpretation: channelInterpretation
		});

		// practice good blob url hygiene ??
		// URL.revokeObjectURL(url);

		// listen for messages from the processor (to tell us it's hungry)
		node.port.onmessage = event -> {
			if (event.data.type == 'dataRequest') {
				// Generate and send more data immediately
				if (isPlaying) {
					generateAndSendBuffer();
				}
			} else if (event.data.type == 'bufferStatus') {
				// debug
				// trace('Buffer queue: ${event.data.queueLength}, Samples: ${event.data.samplesProcessed}, Silent: ${event.data.silentSamples}');
			}
		}

		// connect to output
		node.connect(this.audioContext.destination);

		isInitialized = true;
		trace('audio-stream-processor initialized');
	}

	function generateAndSendBuffer() {
		var buffL = new Float32Array(bufferSize);
		var buffR = new Float32Array(bufferSize);
		audioSource.getAudio(buffL, buffR, bufferSize);
		streamAudioData(buffL, buffR);
	}

	function streamAudioData(buffL:Float32Array, buffR:Float32Array) {
		if (audioContext.state == SUSPENDED) {
			trace('to do .. Resuming suspended audio context...');
			audioContext.resume();
		}

		node.port.postMessage({
			type: 'audioData',
			leftBuffer: buffL,
			rightBuffer: buffR,
		});
	}

	function getSamplingRate():Float {
		return audioContext.sampleRate;
	}

	/* begin playback, starts requesting audio data */
	function play():Void {
		if (node == null) {
			initAudioWorkletNode();
		}

		if (!isInitialized) {
			trace('AudioWorklet not initialized');
			return;
		}

		if (audioContext.state == SUSPENDED) {
			audioContext.resume();
		}

		isPlaying = true;
		node.port.postMessage({type: 'start'});
		trace('Audio playback started');
	}

	function playModule(moduleBytes:Bytes):Void {
		var intArray = new Int8Array(moduleBytes.getData());
		Replay.initialise(intArray, Std.int(getSamplingRate()));
		setAudioSource(Replay.getSource());
		moduleReady.then(_ -> play());
	}


	/* stop playback completely, clears all buffers */
	function stop():Void {
		if (node == null) {
			return;
		}
		samplesProcessed = 0;
		isPlaying = false;
		node.port.postMessage({type: 'stop'});
		trace('Audio playback stopped');
	}

	/* pause playback, keeps buffers for seamless resume */
	function pause() {
		if (node == null) {
			return;
		}

		isPlaying = false;
		node.port.postMessage({type: 'pause'});
		trace('Audio playback paused');
	}

	/* resume from pause */
	function resume() {
		if (node == null) {
			return;
		}

		if (audioContext.state == SUSPENDED) {
			audioContext.resume();
		}

		isPlaying = true;
		node.port.postMessage({type: 'resume'});
		trace('Audio playback resumed');
	}

	function setAudioSource(audioSource:IAudioSource):Void {
		this.audioSource = audioSource;
		isInitialized = true;
	}

	function getBufferSize():Int {
		return bufferSize;
	}

	function getSamplesProcessed():Int {
		return samplesProcessed;
	}
}
