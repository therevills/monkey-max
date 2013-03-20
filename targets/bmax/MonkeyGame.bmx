SuperStrict

Global _errStack:TList = New TList
Global _errInfo:String = ""

'${CONFIG_BEGIN}
'${CONFIG_END}

AppTitle = BMAX_WINDOW_TITLE

Global _depth:Int = 0
If Upper(BMAX_WINDOW_FULLSCREEN) = "TRUE"
	_depth = 32
EndIf

Function FixDataPath$( path$ )
	If path.ToLower().Contains("monkey://data/") Then 
		path = "data/"+path[14..]
	EndIf
	Print "FDP = "+path
	Return path
EndFunction

Graphics  BMAX_WINDOW_WIDTH.ToInt(), BMAX_WINDOW_HEIGHT.ToInt(), _depth

bbInit()
bbMain()

'${TRANSCODE_BEGIN}
'${TRANSCODE_END}
