
Private
Global _bmaxGame:BBBMaxGame
Public

?Win32
Extern "Win32"
	Function SHGetFolderPath:Int(hwndOwner:Byte Ptr, nFolder:Int, hToken:Byte Ptr, dwFlags:Int, pszPath:Short Ptr) = "SHGetFolderPathW@20"
End Extern

Const CSIDL_APPDATA:Int = $001A
Const CSIDL_DESKTOPDIRECTORY:Int = $0010
Const CSIDL_PERSONAL:Int = $0005
Const CSIDL_PROFILE:Int = $0028

Const SHGFP_TYPE_CURRENT:Int = 0
?

?MacOS
Extern
	Function FSFindFolder:Int( vRefNum:Int ,folderType:Int ,createFolder:Int ,foundRef:Byte Ptr )
	Function FSRefMakePath:Int( ref:Byte Ptr,path:Byte Ptr, maxPath:Int )
End Extern

Const kUserDomain:Int = -32763
Const kApplicationSupportFolderType:Int = Asc("a") Shl 24 | Asc("s") Shl 16 | Asc( "u") Shl 8 | Asc("p")

Function getPath:String( folderType:Int )
	Local buf:Byte[1024],ref:Byte[80]

	If FSFindFolder( kUserDomain, folderType, False, ref ) Return Null
	If FSRefMakePath( ref,buf,1024 ) Return Null
		
	Return String.FromCString( buf )
End Function
?

Function GetUserDataFolder:String()
	Local path$
	?Win32
	Local b:Short[] = New Short[MAX_PATH]
'	Local ret:Int = SHGetFolderPath(Null, CSIDL_PERSONAL, Null, SHGFP_TYPE_CURRENT, b)
	Local ret:Int = SHGetFolderPath(Null, CSIDL_APPDATA, Null, SHGFP_TYPE_CURRENT, b)
	path$ = String.fromWString(b)
	?
	?MacOS
	path$ = getPath( kApplicationSupportFolderType )
	?
	Return path$
End Function

Type BBDisplayMode
	Field width:Int
	Field height:Int
	Field format:Int
	Field hertz:Int
	Field flags:Int

	Method New(width:Int, height:Int, format:Int, hertz:Int, flags:Int)
		Self.width = width
		Self.height = height
		Self.format = format
		Self.hertz = hertz
		Self.flags = flags
	End Method
End Type

Type BBBMaxGame Extends BBGame
	Field dead:Int=False
	Field suspended:Int=False
	
	Field updateRate:Int=0
	Field updateNext:Double=0
	Field updatePeriod:Double=0
	
	Field startMillis:Float=0
	
	Field joyButtonStates:Int[32]
	Field keyStates:Int[512]
	Field mouseLastX:Float
	Field mouseLastY:Float
	
	'static functions
	Function BMaxGame:BBBMaxGame()
		'copied this style of singleton from win8game.cpp
		Return _bmaxGame
	End Function
	
	'constructor/destructor
	Method New()
		_bmaxGame = Self
	End Method
	
	'events
	Method OnCreate:Int()
		Return 0
	EndMethod
	
	Method OnSuspend:Int()
		Return 0
	EndMethod
	
	Method OnResume:Int()
		Return 0
	EndMethod

	Method OnUpdate:Int()
		Return 0
	EndMethod
		
	Method OnRender:Int()
		Return 0
	EndMethod
	
	'internal
	Method Run()
		'dont think we need to do this anymore as it is handled by app?
		'timing setup
		startMillis=.MilliSecs()
		SetUpdateRate(0)
		
		'create and first render
		StartGame()
		RenderGame()
		
		'main loop
		While AppTerminate() = False
			If CFG_MOJO_AUTO_SUSPEND_ENABLED = "1"
				While PeekEvent()
					PollEvent()
					
					Select EventID()
						Case EVENT_APPSUSPEND
							If Not suspended
								suspended=1
								SuspendGame()
							EndIf
						Case EVENT_APPRESUME
							If suspended
								ResumeGame()
								suspended=0
							EndIf
					EndSelect
				Wend
			EndIf
			
			If Not updatePeriod Return'this will quit the app?????
			Local updates:Int = 0
			
			'multiple updates
			Repeat
				updateNext:+updatePeriod
				
				'need to poll input (or maybe this should be before the multiple updates?)
				PollInput()
				
				UpdateGame()
'				Exit
				
				If Not updatePeriod Exit
				If updateNext > .MilliSecs()
					Exit
				EndIf
				
				updates:+1
				If updates = 7
					updateNext = .Millisecs()
					Exit
				EndIf
			Forever
			
			'render
			RenderGame()
			
			'sleepy time
			Local del:Int = updateNext - .Millisecs()
			If del < 1 Then del = 1
			Delay(del)
		Wend
	End Method
	
	Method Die(o:Object)
		dead = True
		
		'kill blitzmax graphics
		EndGraphics()
		ShowMouse()
		
		printError(o)
	EndMethod
	
	'input
	Method PollInput()
		' --- this is a helper to poll inputs and send it to monkey ---
		'seems a shame to have so many copies in memory of input states ... but meh
		Local index:Int
		
		'do mouse move
		Local newX:Float = MouseX()
		Local newY:Float = MouseY()
		If newX <> mouseLastX Or newY <> mouseLastY
			mouseLastX = newX
			mouseLastY = newY
			_bmaxGame.MouseEvent(BBGameEvent.MouseMove,0,mouseLastX,mouseLastY)
		EndIf
		
		'do mouse states
		For index = 1 To 3
			If keyStates[index] = False
				If MouseHit(index)
					keyStates[index] = True
					_bmaxGame.MouseEvent(BBGameEvent.MouseDown,index-1,newX,newY)
				EndIf
			Else
				If MouseDown(index) = False
					keyStates[index] = False
					_bmaxGame.MouseEvent(BBGameEvent.MouseUp,index-1,newX,newY)
				EndIf
			EndIf
		Next
		
		'do char
		index = brl.polledinput.GetChar()
		While index > 0
			_bmaxGame.KeyEvent(BBGameEvent.KeyChar,index)
			index = brl.polledinput.GetChar()
		Wend
				
		'do keyboard states
		For index = 8 To 226'this is the range of keys from blitzmax keycodes.bmx
			'check for change in state
			If keyStates[index] = False
				'check for hit
				If KeyHit(index)
					keyStates[index] = True
					_bmaxGame.KeyEvent(BBGameEvent.KeyDown,index)
				EndIf
			Else
				'check for release
				If KeyDown(index) = False
					keyStates[index] = False
					_bmaxGame.KeyEvent(BBGameEvent.KeyUp,index)
				EndIf				
			EndIf
		Next
	End Method
	
	Method PollJoystick:Int( port:Int,JoyX:Float[],JoyY:Float[],JoyZ:Float[],buttons:Int[] )
		'oppertunity to update teh joystick from blitzmax please
		
		'check if this joystick exists
		If port >= JoyCount() Return False
		
		'axis
		JoyX[0] = pub.FreeJoy.JoyX(port)
		JoyY[0] = pub.FreeJoy.JoyY(port)
		JoyZ[0] = pub.FreeJoy.JoyZ(port)
		
		'buttons
		For Local index:Int = 0 Until buttons.Length
			If joyButtonStates[index] = False
				If JoyHit(index,port)
					joyButtonStates[index] = True
				EndIf
			Else
				If JoyDown(index,port) = False
					joyButtonStates[index] = False
				EndIf
			EndIf
			buttons[index] = joyButtonStates[index]
		Next
		
		'there was a joystick!
		Return True
	End Method
	
	'resource loading
	Method LoadBitmap:TImage(path:String)
		Local flags:Int = MASKEDIMAGE
		If Int(CFG_MOJO_IMAGE_FILTERING_ENABLED) flags = flags | FILTEREDIMAGE
		If Int(CFG_BMAX_IMAGE_MIPMAPPED_ENABLED) flags = flags | MIPMAPPEDIMAGE
		Return LoadImage(path,flags)
	End Method
	
	Method LoadSample:TSound(path:String,flags:Int=0)
		Return LoadSound(path,flags)
	End Method
	
	'api
	Method SetUpdateRate:Int(hertz:Int)
		updateRate = hertz
		
		If hertz
			updatePeriod = 1000.0/hertz
			updateNext = .MilliSecs() +updatePeriod
		Else
			updatePeriod = 0
		EndIf
		
		Return 0
	EndMethod

	Method SaveState:Int( State:String )
        Local dir:String = GetUserDataFolder() + "/" + CFG_BMAX_WINDOW_TITLE
        CreateDir( dir )
		SaveText(state, dir + "/.monkeystate" )
		Return 0
	EndMethod
	
	Method LoadState:String()
        Local file:String = GetUserDataFolder() + "/" + CFG_BMAX_WINDOW_TITLE + "/.monkeystate"
		Try
			Return LoadText( file )
		Catch ReadFail:Object
			Return ""
		EndTry
	EndMethod
	
	Method OpenURL:Int(url:String)
		.OpenURL(url)
	End Method
	
	Method SetMouseVisible(visible:Int)
		If visible
			ShowMouse()
		Else
			HideMouse()
		EndIf
	End Method

	Method PathToFilePath:String(path:String)
		'before coding this I wonder if this replaces teh old FixDataPath() function???
		If path.StartsWith( "monkey:" ) = False
			Return path
			
		ElseIf path.StartsWith( "monkey://data/" )
			Return "./data/"+path[14..]
			
		ElseIf path.StartsWith( "monkey://internal/" )
			Return "./internal/"+path[18..]
			
		ElseIf path.StartsWith( "monkey://external/" )
			Return "./external/"+path[18..]
			
		EndIf
		
		'...yup it is :D
	End Method
End Type
