# haxe bindings for ibxm

[ibxm](https://github.com/martincameron/micromod) is

> A player library for the ProTracker MOD, Scream Tracker 3 S3M, and FastTracker 2 XM music formats for Javascript (HTML5 Web Audio), Java and ANSI C.

# status

So far I've only tested on linux but the bindings for hashlink, JavaScript, and hxcpp are working.

The bindings enable

 - read module meta data, e.g. instrument/sample names
 - generate audio from the module sequence

# Testing it

Clone the source

```
git clone --recursive https://github.com/jobf/ibxm-hx
```



## test-pure (render audio to wav file, pure haxe build)

Minimal example of generating the audio and writing it to disk as a wav file.

### Install dependencies

```
# format (read and write various file formats including wav)
haxelib install format

# ibxm-hx (this haxelib)
haxelib git ibxm-hx https://github.com/jobf/ibxm-hx

```

### hashlink

Build it

```
haxe build-hl.hxml
```

Run it (assumes hashlink is available on PATH)

```
cd bin/hl
hl main.hl ../../assets/yesod.xm
```

output.wav will have been written to the folder

### cpp

Build it

```
haxe build-cpp.hxml
```

Run it

```
cd bin/cpp
./Main ../../assets/yesod.xm
```

output.wav will have been written to the folder

### js

Build it

```
haxe build-js.hxml
```

Open assets/index.html in a web browser.

Click Browse... and choose the assets/yesod.xm file

Click Render to wav and the output.wav will be downloaded




## test-lime (render audio to sound card, build depends on https://lime.openfl.org/)

Minimal example of playing the module back via sound card.

### Install dependencies

```
# lime (general appliation layer for graphics and audio back end)
haxelib install lime

# peote-view (open gl render lib)
haxelib install peote-view

# ibxm-hx (this haxelib)
haxelib git ibxm-hx https://github.com/jobf/ibxm-hx
```

### Run it

You want to be in the correct path

```
cd test-lime
```

Then you can run either with hashlink, web browser, or native.

```
# hashlink jit
lime test hl

# web browser
lime test html5

# linux
lime test linux

# windows (as yet untested)
lime test windows

# hashlink c also works, at least on linux
lime test hlc
```

## test app with ui

See https://github.com/jobf/ibxm-hx-test


# to do

- test on windows
- make locateIbxmHaxelibPath more resilient (add additional check for haxelib version?)
- document build macro
- more comments
- unify ModuleData api ?
- unit tests ?
- expose control over looping
- port reverb to haxe
- extract web audio streaming api so it can be used in other places