' ***** Start filestream.bmx ******
Type BBFileStream Extends BBStream

	Method Open:Int( path:String:String,mode )
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
		
		_position=_stream.Position
		_length=_stream.Length
		
		Return True
	End Method

	Method close()
		If _stream=Null Return
		
		_stream.close()
		_stream=Null
		_position=0
		_length=0
	End Method
	
	Method Eof:Int()
		If _stream=Null Return -1
		
		If _position=_length Return True
		Return False
	End Method
	
	Method Length:Int()
		Return _length
	End Method
	
	Method Position:Int()
		Return _position
	End Method
	
	Method seek:Int(Position:Int)
		Try
			_stream.seek( Position)
			_position=_stream.Pos()
		Catch ex:Object
		EndTry
		Return _position
	End Method
		
	Method read:Int( buffer:BBDataBuffer,Int offset:Int,Count:Int )
		If _stream=Null Return 0

		Try
			Local:Int n=_stream.read( buffer._data,offset,Count )
			_position:+n
			Return n
		Catch ex:Object
		EndTry
		Return 0
	End Method
	
	Method write:Int( buffer:BBDataBuffer,offset:Int,Count:Int )
		If _stream=Null Return 0
		
		Try
			_stream.write( buffer._data,offset,Count );
			_position+=Count;
			If( _position>_length ) _length=_position;
			Return Count;
		Catch ex:Object
		EndTry
		Return 0
	End Method

	Field _stream:TStream
	Field _position:Int
	Field _length:Int
End Type
' ***** End filestream.bmx ******


