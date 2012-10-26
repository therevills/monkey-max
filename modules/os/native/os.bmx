Function BmaxEnd(ret:Int)
	End
EndFunction

Function BmaxAppPath:String()
	Return AppDir
EndFunction

?Win32

Function BMaxExecute( tCommand:String, tSilent:Int = True )
	' start doesnt work unless called via a CMD prompt (env var issue?)
	'If tSilent = True
	'	system_( "start "+tCommand )
	'Else
		system_( tCommand )
	'EndIf
EndFunction	

?Linux

Function BMaxExecute( tCommand:String, tSilent:Int = True )
	If tSilent = True
		system_( tCommand+" &" )
	Else
		system_( tCommand )
	EndIf
EndFunction

?


Function BMaxAppArgs:String[]()
	Return AppArgs
EndFunction

Function BmaxSetEnv( name:String, value:String )
	putenv_ name+"="+value
EndFunction

Function BmaxHostOS:String()
?Win32
	Return "win32"
?MacOS
	Return "macos"
?Linux
	Return "linux"
?
EndFunction