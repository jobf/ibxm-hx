import lime.app.Application;
import peote.view.Load;
import ibxm.Replay;

class Main extends Application {
	override function onWindowCreate() {
		#if js
		
		// web browser cannot start audio until a gesture has been made so bind to mouse event
		var isPlaying:Bool = false;
		window.onMouseDown.add((x, y, button) -> {
			if (!isPlaying) {
				Load.bytes("assets/yesod.xm", data -> {
					Replay.loadModule(new js.lib.Int8Array(data.getData()));

					var driver = juice.driver.js.AudioDriver.create();
					driver.setSampleSource(Replay.getSource());
					driver.play();
				});

				isPlaying = true;
			}
		});

		// let the people know they need to click
		var peoteView = new peote.view.PeoteView(window);
		var display = new peote.view.Display(0, 0, window.width, window.height);
		peoteView.addDisplay(display);
		var program = new peote.view.text.TextProgram();
		display.addProgram(program);
		program.add(new peote.view.text.Text(16, 16, "Click to play!"));

		#else
		
		Load.bytes("assets/yesod.xm", data -> {
			Replay.loadModule(data);

			var driver = new juice.driver.lime.AudioDriver();
			driver.setSampleSource(Replay.getSource());
			driver.play();
		});
		
		#end
	}
}
