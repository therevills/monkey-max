Global _errInfo:String = ""
Global _errStack:TList = New TList

Type BBMonkeyGame Extends BBBMaxGame
	'static functions
	Function Main:Int( args:String[]=Null)
		Local game:BBMonkeyGame = New BBMonkeyGame
		
		Try
			'setup app title
			AppTitle = CFG_BMAX_WINDOW_TITLE
			
			'select driver
			?Win32
				Select CFG_BMAX_GRAPHICS_DRIVER.ToLower()
					Case "dx7","directx7"
						SetGraphicsDriver(D3D7Max2DDriver())
					Case "gl","opengl"
						SetGraphicsDriver(GLMax2DDriver())
					Default
						'default to directx9 in windows
						SetGraphicsDriver(D3D9Max2DDriver())
				End Select
			?Not Win32
				'use gl Driver on Max and linux
				SetGraphicsDriver(GLMax2DDriver())
			?
			
			'start graphics window
			Local depth:Int = 0
			If CFG_BMAX_WINDOW_FULLSCREEN="1" depth = 32
			Graphics(Int(CFG_BMAX_WINDOW_WIDTH), Int(CFG_BMAX_WINDOW_HEIGHT),depth)
			
			'setup monkey app
			bbInit()
			bbMain()
			
		Catch ex:Object
			game.Die(ex)
			End
			
		EndTry
		
		If game.Delegate()=Null End
		
		game.Run()
	End Function
End Type
