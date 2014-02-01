' ***** Start filestream.bmx ******
Type BBFileStream

	Method Open:Int( path:String,mode:String )
		If _stream<>Null Return False
		
		Local fmode:String
		If mode="r" 
			fmode="rb"
		ElseIf mode="w"
			fmode="wb"
		ElseIf mode="u"
			fmode="rb+"
		Else
			Return False
		EndIf

		_stream=BBGame.Game().OpenFile( path,fmode )
		If _stream=Null  Return False
		
		Return True
	End Method

	Method close()
		If _stream=Null Return
		
		_stream.close()
		_stream=Null
	End Method
	
	Method Eof:Int()
		If _stream=Null Return -1
		
		If Position()=Length() Return True
		Return False
	End Method
	
	Method Length:Int()
		If _stream=Null Return -1
        Return _stream.Size()
	End Method
	
	Method Position:Int()
		If _stream=Null Return -1
        Return _stream.Pos()
	End Method
	
	Method seek:Int(Pos:Int)
		Try
			_stream.seek(Pos)
		Catch ex:Object
		EndTry
		Return Position()
	End Method
		
	Method read:Int( buffer:BBDataBuffer,offset:Int,Count:Int )
		If _stream=Null Return 0

		Try
            seek(offset)
			Local n:Int=_stream.read( Varptr buffer._data,Count )
			Return n
		Catch ex:Object
		EndTry
		Return 0
	End Method
	
	Method write:Int( buffer:BBDataBuffer,offset:Int,Count:Int )
		If _stream=Null Return 0
		
		Try
            seek(offset)
			Local n:int=_stream.write( buffer._data,Count );
			Return n;
		Catch ex:Object
		EndTry
		Return 0
	End Method

	Field _stream:TStream
End Type
' ***** End filestream.bmx ******


