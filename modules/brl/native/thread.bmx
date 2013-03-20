' ***** Start thread.bmx ******
Type BBThread
	Field _running:Int = False
	
	Method Start()
	End Method
	
	Method IsRunning:Int()
		Return _running
	End Method
	
	Method Run__UNSAFE__()
		_running = False
	End Method
EndType
' ***** End thread.bmx ******


