' ***** Start tcpstream.bmx ******
Type BBTcpStream Extends BBStream
	
	Field _sock:TSocket
	Field _input:TSocketStream
	Field _output:TStream
	Field _state:Int'0=INIT, 1=CONNECTED, 2=CLOSED, -1=ERROR

	Method Connect:Int( addr:String,port:Int )
	
		If _state<>0 Return False
		
		Try
			Local ip:Int = HostIp(addr)
			If ip = 0 Return False
			
			_sock=CreateTCPSocket()
			If _sock.Connect(ip,port)
				_input = CreateSocketStream(_sock)
				_output= _input'????
				_state=1
				return true
			EndIf
			
		Catch ex:Object
		EndTry
		
		_state=1
		_sock=null
		return false
	End Method
	
	Method ReadAvail:Int()
		Try
			Return _sock.ReadAvail()
		Catch ex:Object
		EndTry
		_state=-1
		return 0
	End Method
	
	Method WriteAvail:Int()
		return 0
	End Method
	
	Method Eof:Int()
		If _state>=0
			If _state = 2 Return 1
			Return 0
		EndIf
		Return -1
	End Method
	
	Method close:Int()

		If _sock=Null Return
		
		Try
			_sock.close()
			if( _state=1 ) _state=2
		Catch ex:Object
			_state=-1
		EndTry
		_sock=null
	End Method
	
	Method read:Int( buffer:BBDataBuffer,offset:Int,Int Count:Int )

		If _state<>1 Return 0
		
		Try
			Local n:Int=_input.read( buffer._data,offset,Count )
			If n>=0 Return n
			_state=2
		Catch ex:Object
			_state=-1
		EndTry
		return 0
	End Method
	
	Method write:Int( buffer:BBDataBuffer,offset:Int ,Count:Int )

		If _state<>1 Return 0
		
		try
			_output.write( buffer._data,offset,Count )
			return count
		Catch ex:Object
			_state=-1
		EndTry
		return 0
	End Method
End Type
' ***** End tcpstream.bmx ******


