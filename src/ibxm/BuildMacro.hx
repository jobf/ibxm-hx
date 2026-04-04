package ibxm;

#if macro
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Compiler;

class BuildMacro {
	public static function init():Void {
		if (Context.defined("cpp")) {
			// nothing to do for cpp builds
			return;
		}

		if (Context.defined("js")) {
			copyIbxmJs();
			return;
		}

		if (Context.defined("hl") || Context.defined("hlc")) {
			buildAndCopyHdll();
		}
	}

	public static function buildAndCopyHdll():Void {
		// add a callback for after compilation, it will build copy the hdll dependency to output
		Context.onAfterGenerate(() -> {
			var libPath = locateIbxmHaxelibPath();
			if (libPath == null) {
				Context.error("ibxm-js: could not find buildIbxmHdll.xml in class paths", Context.currentPos());
				return;
			}

			var outputDir = Path.directory(Compiler.getOutput());
			if (Context.defined("lime")) {
				outputDir = Path.join([Path.directory(outputDir), "bin"]);
			}

			var prevCwd = Sys.getCwd();
			Sys.setCwd(libPath);

			var target = "hl";
			if (Context.defined("hlc")) {
				target = " hlc";
			}

			var result = Sys.command('haxelib run hxcpp buildIbxmHdll.xml $target');
			Sys.setCwd(prevCwd);

			if (result != 0) {
				Context.error("ibxm-hx: hdll build failed", Context.currentPos());
				return;
			}

			var hdllDir = Path.join([libPath, "glue/bin"]);
			for (file in FileSystem.readDirectory(hdllDir)) {
				if (Path.extension(file) == "hdll") {
					File.copy(Path.join([hdllDir, file]), Path.join([outputDir, file]));
				}
			}
		});
	}

	public static function copyIbxmJs():Void {
		if (Context.defined("lime")) {
			// lime js dependency handled by include.xml
			return;
		}

		// add a callback for after compilation, it will copy the js dependency to output
		Context.onAfterGenerate(() -> {
			var libPath = locateIbxmHaxelibPath();
			if (libPath == null) {
				Context.error("ibxm-hx: could not find library path", Context.currentPos());
				return;
			}

			var outputDir = Path.directory(Compiler.getOutput());
			File.copy(Path.join([libPath, "external/micromod/ibxm-js/IBXM.js"]), Path.join([outputDir, "IBXM.js"]));
		});
	}

	static function locateIbxmHaxelibPath():String {
		for (path in Context.getClassPath()) {
			var parent = Path.directory(Path.removeTrailingSlashes(path));
			if (FileSystem.exists(Path.join([parent, "buildIbxmHdll.xml"]))) {
				return parent;
			}
		}
		return null;
	}
}
#end
