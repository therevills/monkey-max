' ***** Start stream.bmx ******
Type BBStream Abstract

	Method Eof:Int()
		return 0
	End Method
	
	Method close()
	End Method
	
	Method Length:Int()
		return 0
	End Method
	
	Method Position:Int()
		return 0
	End Method
	
	Method seek:Int( Position:Int )
		return 0
	End Method
	
	Method read:Int( buffer:BBDataBuffer,offset:Int,Count:Int )
		return 0
	End Method
	
	Method write:Int( buffer:BBDataBuffer,offset:Int,Count:Int )
		return 0
	End Method
End Type
' ***** End stream.bmx ******


