Global _errInfo:String = ""
Global _errStack:TList = New TList

Type BBMonkeyGame Extends BBBMaxGame
	'static functions
	Function Main:Int( args:String[]=Null)
		Local game:BBMonkeyGame = New BBMonkeyGame
		
		Try
			'setup window and graphics
			AppTitle = CFG_BMAX_WINDOW_TITLE
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
