
Type Thttp
	Field sock:TSocket
	Field stream:TStream
	Field host:String
	Field agent:String = "SFCH/1.0"
	Field autoClose:Int
	
	Method Open:Int(host:String, autoClose:Int = False) 
		Self.sock = CreateTCPSocket() 
		If ConnectSocket(Self.sock, HostIp(host), 80) 
			Self.host = host
			Self.stream = CreateSocketStream(Self.sock) 
			Self.autoClose = autoClose
			Return True
		Else
			Return False
		End If
	End Method
	
	Method Get:String(get:String = "") 
		Local buffer:String
		WriteLine(stream, "GET /" + get + " HTTP/1.0~nHost: " + Self.host + "~nUser-Agent: " + Self.agent + "~n~n") 
		While Not Eof(stream) 
			buffer:+ReadLine(stream) + "~n"
		Wend
		If autoClose Close() 
		Return Left(buffer, Len(buffer) - 1) 
	End Method
	
	Method Post:String(page:String = "", data:String = "") 
		Local buffer:String
		WriteLine(stream, "POST /" + page + " HTTP/1.0~nHost: " + Self.host + "~nUser-Agent: " + Self.agent + "~nContent-Length: " + Len(data) + "~nContent-Type: application/x-www-form-urlencoded~n~n" + data) 
		While Not Eof(stream) 
			buffer:+ReadLine(stream) + "~n"
		Wend
		If autoClose Close() 
		Return Left(buffer, Len(buffer) - 1) 
	End Method

	Method PostKeyValues:String(page:String = "", keys:String[] , values:String[] ) 
		Local buffer:String
		Local data:String
		Local i:Int
		For i = 0 To keys.Length - 1
			data:+UrlEncode(keys[i] ) + "=" + UrlEncode(values[i] ) + "&"
		Next
		data = Left(data, Len(data) - 1) 
		WriteLine(stream, "POST /" + page + " HTTP/1.0~nHost: " + Self.host + "~nUser-Agent: " + Self.agent + "~nContent-Length: " + Len(data) + "~nContent-Type: application/x-www-form-urlencoded~n~n" + data) 
		While Not Eof(stream) 
			buffer:+ReadLine(stream) + "~n"
		Wend
		If autoClose Close() 
		Return Left(buffer, Len(buffer) - 1) 
	End Method
	
	Method Close() 
		If Self.stream CloseStream(Self.stream) 
		If Self.sock CloseSocket(Self.sock) 
	End Method

	Function UrlEncode:String(url:String) 
		Local buffer:String
		Local Char:Int
		Local i:Int
		For i = 1 To Len(url) 
			Char = Asc(Mid(url, i, 1)) 
			If(Char >= 48 And Char <= 57) Or (Char >= 65 And Char <= 90) Or (Char >= 97 And Char <= 122) Or Char = 43 Or Char = 45 Or Char = 46 Or Char = 95
				buffer = buffer + Chr(Char) 
			Else
				buffer = buffer + "%" + Right(Hex(Char), 2) 
			End If
		Next
		Return buffer
	End Function
	
	Function UrlDecode:String(url:String) 
		Local sHex:String = "0123456789ABCDEF"
		Local buffer:String
		Local i:Int
		For i = 1 To Len(url) 
			If Mid(url, i, 1) = "%"Then
				buffer = buffer + Chr(Instr(sHex, Mid(url, i + 1, 1)) Shl 4 + Instr(sHex, Mid(url, i + 2, 1)) - 17) 
				i:+2
			Else
				buffer = buffer + Mid(url, i, 1) 
			End If
		Next
		Return buffer
	End Function	
End Type

Function Sender:Object( obj:Object )
    Local data:BBHttpRequest = BBHttpRequest( obj )
    data._status = 0
    Local ret:String
    Local http:THTTP = New THTTP
    If( data._method = "GET" )
        If http.Open( data._host )
            ret = http.Get( data._page )
        End If
        http.Close()
    Elseif( data._method = "POST" )
        If http.Open( data._host )
            ret = http.Post( data._page, data._text )
        End If
        http.Close()
    Endif
    
    If( ret <> "" )
        Local tmp:String
        Local s:Int
        s = ret.Find( "~n" )
        tmp = Left( ret, s )
        Local ss:String[]
        ss = tmp.Split( " " )
        If( ss.length >= 3 )
            data._status = ss[1].ToInt()
        Endif
        s = ret.Find( "~n~n" )
        ret = Right( ret, ret.length - (s + 2) )
    Endif

    data._response = ret
    Return Null
End Function

Type BBHttpRequest
    Field _method:String
    Field _host:String
    Field _page:String
    Field _text:String
    Field _thread:TThread
    Field _status:Int
    Field _response:String

    Method Open( requestMethod:String, url:String )
        _method = requestMethod.ToUpper()
        _host = ""
        _page = ""
        Local s:Int = url.Find( "//" )
        If( s <> -1 )
            url = Right( url, url.length - (s+2) )
        Endif
        s = url.Find( "/" )
        If( s <> -1 )
            _host = Left( url, s )
            _page = Right( url, url.length - (s + 1) )
        Else
            _host = url
        Endif
    End Method

    Method SetHeader( name:String, value:String )
    End Method

    Method Send()
        _thread = CreateThread( Sender, Self )
    End Method

    Method SendText( text:String, encoding:String )
        _text = text
        Send()
    End Method

    Method ResponseText:String()
        Return _response
    End Method

    Method Status:Int()
        Return _status
    End Method

    Method BytesReceived:Int()
        Return _response.length
    End Method

    Method IsRunning:Int()
       If( _thread = Null )
            Return False
        Endif
        Return _thread.Running()
    End Method    
End Type
