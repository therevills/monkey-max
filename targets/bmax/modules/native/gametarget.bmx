
Type BBGameEvent
	Const None:Int=0
	Const KeyDown:Int=1
	Const KeyUp:Int=2
	Const KeyChar:Int=3
	Const MouseDown:Int=4
	Const MouseUp:Int=5
	Const MouseMove:Int=6
	Const TouchDown:Int=7
	Const TouchUp:Int=8
	Const TouchMove:Int=9
	Const MotionAccel:Int=10
End Type

Type BBGameDelegate
	Method StartGame() Abstract
	Method SuspendGame() Abstract
	Method ResumeGame() Abstract
	Method UpdateGame() Abstract
	Method RenderGame() Abstract
	Method KeyEvent( ev:Int,data:Int ) Abstract
	Method MouseEvent( ev:Int,data:Int,X:Float,Y:Float ) Abstract
	Method TouchEvent( ev:Int,data:Int,X:Float,Y:Float ) Abstract
	Method MotionEvent( ev:Int,data:Int,X:Float,Y:Float,Z:Float ) Abstract
	Method DiscardGraphics() Abstract
End Type

Type BBGame

	Global _game:BBGame
	
	Field _delegate:BBGameDelegate
	Field _keyboardEnabled:Int
	Field _updateRate:Int
	Field _debugExs:Int
	Field _started:Int
	Field _suspended:Int
	Field _startms:Int
	
	Method New()
		_game=Self
		_debugExs = (CFG_CONFIG="debug")
		_startms = .MilliSecs()
	End Method
	
	Function Game:BBGame()
		return _game
	End Function
	
	Method SetDelegate( delegate_:BBGameDelegate )
		_delegate=delegate_
	End Method
	
	Method Delegate:BBGameDelegate()
		return _delegate
	End Method
	
	Method SetKeyboardEnabled( enabled:Int )
		_keyboardEnabled=enabled
	End Method
	
	Method SetUpdateRate( hertz:Int )
		_updateRate=hertz
	End Method
	
	Method MilliSecs:Int()
		Return .MilliSecs()-_startms
	End Method
	
	Method GetDate:Int( date:Int[] )
		Local n:Int=date.Length

        If n>0
			'date
			Local dateBits:String[] = CurrentDate().Split(" ")
            
            'year
            date[0]=Int(dateBits[2])

            If n>1

                'month
                Local month:String = dateBits[1].ToUpper()
                Select month
                    Case "JAN"
                        date[1] = 1
                    Case "FEB"
                        date[1] = 2
                    Case "MAR"
                        date[1] = 3
                    Case "APR"
                        date[1] = 4
                    Case "MAY"
                        date[1] = 5
                    Case "JUN"
                        date[1] = 6
                    Case "JUL"
                        date[1] = 7
                    Case "AUG"
                        date[1] = 8
                    Case "SEP"
                        date[1] = 9
                    Case "OCT"
                        date[1] = 10
                    Case "NOV"
                        date[1] = 11
                    Case "DEC"
                        date[1] = 12
                End Select
			
                If n>2
                    'day
                    date[2]=Int(dateBits[0])
                    If n>3 
						'time
						Local timeBits:String[] = CurrentTime().Split(":")
						'hours
						date[3]=Int(timeBits[0])
						If n>4 
							'minutes
							date[4]=Int(timeBits[1])
							If n>5 
								'seconds
								date[5]=Int(timeBits[2])
								
								'milliseconds
								If n>6 date[6]=MilliSecs()
							EndIf
						EndIf
                    EndIf
                EndIf
            EndIf
		EndIf
	End Method
	
	Method CurrentDate:String()
		Return .CurrentDate()
	End Method
	
	Method CurrentTime:String()
		Return .CurrentTime()
	End Method
	
	Method SaveState:Int(  State:String )
		Return -1
	End Method
	
	Method LoadState:String()
		Return ""
	End Method
	
	Method LoadString:String( path:String )
		Try
			Local stream:TStream = OpenInputStream( path )
			If stream=Null Return ""
			Local text:String = stream.ReadString(stream.size())
			stream.close()
			Return text
		Catch ReadFail:Object
			Return ""
		EndTry
	End Method
	
	Method PollJoystick:Int( port:Int,JoyX:Float[],JoyY:Float[],JoyZ:Float[],buttons:Int[] )
		Return False
	End Method
	
	Method OpenURL( url:String )
	End Method

	Method GetDisplayModes:BBDisplayMode[]()
		Return New BBDisplayMode[0]
	End Method

	Method GetDesktopMode:BBDisplayMode()
		Return Null
	End Method

	Method GetDeviceWidth:Int()
		Return bb_framework__1D_1E_1V_1I_1C_1E__1W_1I_1D_1T_1H
	End Method

	Method GetDeviceHeight:Int()
		Return bb_framework__1D_1E_1V_1I_1C_1E__1H_1E_1I_1G_1H_1T
	End Method

	Method SetMouseVisible( visible:Int )
	End Method
	
	'extension ?????
	Method PathToFilePath:String(path:String )
		Return ""
	End Method
	
	Method OpenFile:TStream( path:String,mode:String )
		Try
			Local stream:TStream
			path = PathToFilePath( path )
			
			'use fopen modes
			Select mode
				Case "r","rb"
					'read only, must exist
					stream = .ReadFile(path)
					
				Case "w","wb"
					'write an empty file
					stream = .WriteFile(path)
					
				Case "a","ab"
					'append
					stream = .OpenFile(path)
					stream.seek(stream.size()-1)
					
				Case "r+","rb+"
					'read only, must exist
					stream = .OpenFile(path)
					
				Case "w+","wb+"
					'write an empty file
					stream = .WriteFile(path)
					
				Case "a+","ab+"
					'append
					stream = .OpenFile(path)
					stream.seek(stream.size()-1)
			End Select
			Return stream
			
		Catch ex:Object
		EndTry
		
		return null
	End Method
	
	Method OpenInputStream:TStream(path:String)
		Return OpenFile(path,"r+")
	End Method
	
	Method LoadData:Byte[]( path:String )
	
		Local stream:TStream = OpenInputStream( path )
		If stream=Null Return Null
		
		'//fixme: stream may not have a Length (will always for now though).
		'//
		Local size:Int = stream.size()
		Local Buf:Byte[]=New Byte[size]
		
		Local n:Int=stream.ReadBytes( Buf,size )
		stream.Close()
		If n = size Return Buf
	
		Return Null
	End Method

	'***** INTERNAL *****
	Method Quit()
		'???????????????
		'_delegate=new BBGameDelegate()
	End Method
	
	Method Die:Int( o:Object )
		Local ex:String = String(o)
		If ex =""
			Quit()
			Return False
		EndIf
		
		If _debugExs
			Print( "Monkey Runtime Error : "+String(ex) )
			Print( stackTrace() )
		EndIf
		
		Return True
	End Method
	
	Method StartGame()
	
		If _started Return
		_started=True
		
		Try
			_delegate.StartGame()
		Catch ex:Object
			If Die( ex ) Throw ""
		EndTry
	End Method
	
	Method SuspendGame()
	
		If _started = False Or _suspended  Return
		_suspended=true
		
		Try
			_delegate.SuspendGame()
		Catch ex:Object
			If Die( ex ) Throw ""
		EndTry
	End Method
	
	Method ResumeGame()
	
		If _started = False Or _suspended = False Return
		_suspended=false
		
		Try
			_delegate.ResumeGame()
		Catch ex:Object
			If Die( ex ) Throw ""
		EndTry
	End Method
	
	Method UpdateGame()
	
		If _started = False Or _suspended  Return
		
		Try
			_delegate.UpdateGame()
		Catch ex:Object
			If Die( ex ) Throw ""
		EndTry
	End Method
	
	Method RenderGame()
	
		If _started = False Return
		
		Try
			_delegate.RenderGame()
		Catch ex:Object
			If Die( ex ) Throw ""
		EndTry
	End Method
	
	Method KeyEvent( ev:Int,data:Int )

		If _started = False Return
		
		Try
			_delegate.KeyEvent(ev,data)
		Catch ex:Object
			If Die( ex ) Throw ""
		EndTry
	End Method
	
	Method MouseEvent( ev:Int,data:Int,X:Float,Y:Float )

		If _started = False Return
		
		Try
			_delegate.MouseEvent(ev,data,X,Y)
		Catch ex:Object
			If Die( ex ) Throw ""
		EndTry
	End Method
	
	Method TouchEvent( ev:Int,data:Int,X:Float,Y:Float )

		If _started = False Return
		
		Try
			_delegate.TouchEvent(ev,data,X,Y)
		Catch ex:Object
			If Die( ex ) Throw ""
		EndTry
	End Method
	
	Method MotionEvent( ev:Int,data:Int,X:Float,Y:Float,Z:Float )

		If _started = False Return
		
		Try
			_delegate.MotionEvent(ev,data,X,Y,Z)
		Catch ex:Object
			If Die( ex ) Throw ""
		EndTry
	End Method
End Type
