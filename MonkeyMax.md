## Introduction ##

MonkeyMax is a BlitzMax target for Monkey. It allows you to write Monkey code and output to BlitzMax code, which in turn allows you to run your applications using DirectX7/9 or OpenGL. Also after translating to BlitzMax code, you can then use the BlitzMax debugger.

![http://monkey-max.googlecode.com/svn/trunk/MonkeyMaxLogo.png](http://monkey-max.googlecode.com/svn/trunk/MonkeyMaxLogo.png)

## Disclaimer ##

Shearing is not supported by BlitzMax.
Currently works with Monkey v66b.
Switch to v69 branch for a version that supports monkey v69+

## App config settings ##

MonkeyMax supports the following app config settings:
```
BMAX_WINDOW_TITLE:String = "MonkeyMax Title"
BMAX_WINDOW_WIDTH:Int = 640
BMAX_WINDOW_HEIGHT:Int = 480
BMAX_WINDOW_FULLSCREEN:String = "true"
MOJO_AUTO_SUSPEND_ENABLED:String="true"
MOJO_IMAGE_FILTERING_ENABLED:String="true"
```

Example:
```
Strict

#BMAX_WINDOW_TITLE="Mojo Test"
#BMAX_WINDOW_WIDTH=1024
#BMAX_WINDOW_HEIGHT=768
#BMAX_WINDOW_FULLSCREEN="true"
#MOJO_IMAGE_FILTERING_ENABLED="true"
#MOJO_AUTO_SUSPEND_ENABLED="true"

Import mojo

Global game:MyGame
```


## Installation ##

  1. Download the latest version of MonkeyMax from the repository or download the zip from the [Downloads section](http://code.google.com/p/monkey-max/downloads/list)
  1. Make a copy of your Monkey installation as this will override your files, name it something like MonkeyProBMax
  1. Copy over all the files in MonkeyMax on top of your MonkeyProBMax folder so that they overwrite the folders and files
  1. In your MonkeyProBMax\bin folder, open config.winnt.txt, change the BMAX\_PATH to point to your bmk.exe and save the changes
  1. Open up Monk from your MonkeyProBMax folder
  1. Open up a Monkey project and click Build and Run, select BMAX from the targets and click Build

Hopefully it compiles and executes successfully for you.

# Thanks #

Thanks goes to the following people:
  * Devolonter
  * Karja
  * Mark Sibly
  * Outsider
  * Samah
  * Skn3