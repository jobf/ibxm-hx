package juice;

import haxe.io.Float32Array;
import juice.API;

#if hl
import ibxm.bindings.hl.IbxmHl.IbxmSource;
#elseif cpp
import ibxm.bindings.cpp.IbxmCpp.IbxmSource;
#else
import ibxm.bindings.js.IbxmJs.IbxmSource;
#end

import ibxm.Replay;

class IbxmStream implements ISampleStream {
	final ibxm:IbxmSource;

	public function new(ibxm:IbxmSource) {
		this.ibxm = ibxm;
	}

	public function init(samplingRate:Int) {
		Replay.init(samplingRate);
	}

	public function getAudio(left:Float32Array, right:Float32Array, numSamples:Int):Void {
		ibxm.getAudio(left, right, numSamples);
	}

	public function getAudioInterleaved(output:Float32Array, numSamples:Int):Void {
		ibxm.getAudioInterleaved(output, numSamples);
	}
}
