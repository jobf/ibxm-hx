import lime.app.Application;
import peote.view.Load;

class Main extends Application {
	override function onWindowCreate() {
		#if html5
		
		// web browser cannot start audio until a gesture has been made so bind to mouse event
		var isPlaying:Bool = false;
		window.onMouseDown.add((x, y, button) -> {
			if (!isPlaying) {
				Load.bytes("assets/yesod.xm", data -> new audio.js.AudioPlayer().playModule(data));
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
		
		Load.bytes("assets/yesod.xm", data -> new audio.lime.AudioPlayer().playModule(data));
		
		#end
	}
}
