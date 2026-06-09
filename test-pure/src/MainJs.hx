import js.Browser;
import js.html.InputElement;
import js.html.ButtonElement;

import ibxm.Replay;
import juice.driver.format.AudioDriver;

var sampleRate = 48000;

function main() {
	var fileInput:InputElement = cast Browser.document.getElementById("fileInput");
	var renderBtn:ButtonElement = cast Browser.document.getElementById("renderBtn");

	fileInput.onchange = _ -> renderBtn.disabled = fileInput.files.length == 0;

	renderBtn.onclick = _ -> {
		var file = fileInput.files.item(0);
		var reader = new js.html.FileReader();
		reader.onload = _ -> {
			var ab:js.lib.ArrayBuffer = cast reader.result;
			var int8 = new js.lib.Int8Array(ab);

			var error = Replay.loadModule(int8);
			if (error == "") error = Replay.init(sampleRate);
			if (error != "") {
				Browser.alert('Error: $error');
				return;
			}

			var author = new AudioDriver(Replay.getSongDuration());
			author.setSampleSource(Replay.getSource());
			author.play();
		};
		reader.readAsArrayBuffer(file);
	};
}
