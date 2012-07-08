' ***** Start lang.bmx ******
Global D2R:Float=0.017453292519943295;
Global R2D:Float=57.29577951308232;

Function pushErr()
	_errStack.AddLast( _errInfo );
EndFunction

Function popErr()
	_errInfo=String(_errStack.ValueAtIndex(_errStack.Count()-1))
	_errStack.RemoveLast();
EndFunction

Function stackTrace:String()
	If Not _errInfo.length Return ""
	Local str:String = _errInfo+"~n"
	Local _backwardsStack:TList = _errStack.Reversed()
	For Local s:String = EachIn _backwardsStack
		str :+ s +"~n"
	Next
	Return str
EndFunction

Function printError(err:Object)
	If TBlitzException(err) Then
		Local output:String = TBlitzException(err).ToString()
		Notify(output)
		Print( "Monkey Runtime Error : "+output );
		Print( "" );
		Print( stackTrace() );
	Else
		Notify (err.ToString())
		Print( "" );
		Print( stackTrace() );
	EndIf
EndFunction

Function error( err:String )
	If err = "" Then
		End
	Else
		RuntimeError err;
	EndIf
EndFunction

Function DebugLog:Int( str:String )
	Print(str)
	Return 0
EndFunction

Function DebugStop:Int()
	error("STOP")
	Return 0
EndFunction

Function resize_string_array:String[]( arr:String[], leng:Int )
	Local i:Int = arr.length;
	arr = arr[0..leng];
	If( leng<=i ) Return arr;
	While( i<leng )
		arr[i]="";
		i:+1
	Wend
	Return arr;
EndFunction

Function resize_float_array:Float[]( arr:Float[], leng:Int )
	Local i:Int = arr.length;
	arr = arr[0..leng];
	If( leng<=i ) Return arr;
	While( i<leng )
		arr[i]=0;
		i:+1
	Wend
	Return arr;
EndFunction

Function resize_int_array:Int[]( arr:Int[], leng:Int )
	Local i:Int = arr.length;
	arr = arr[0..leng];
	If( leng<=i ) Return arr;
	While( i<leng )
		arr[i]=0;
		i:+1
	Wend
	Return arr;
EndFunction

Function resize_object_array:Object[]( arr:_Object[],leng:Int )
	Local i:Int=arr.length;
	arr=arr[0..leng];
	If( leng<=i ) Return arr;
	While( i<leng )
		arr[i]=Null;
		i:+1
	Wend
	Return arr;
EndFunction

Function resize_array_array_Int:Int[][]( arr:Int[][], leng:Int )
	Local i:Int = arr.length;
	arr = arr[..leng];
	If( leng<=i ) Return arr;

	For Local l:Int = 0 Until Len(arr)
		arr[l] = arr[l][..leng]
	Next

	While( i<leng )
		arr[0][i]=0;
		i:+1
	Wend
	Return arr;
EndFunction

Function resize_array_array_Float:Float[][]( arr:Float[][], leng:Int )
	Local i:Int = arr.length;
	arr = arr[..leng];
	If( leng<=i ) Return arr;

	For Local l:Int = 0 Until Len(arr)
		arr[l] = arr[l][..leng]
	Next

	While( i<leng )
		arr[0][i]=0;
		i:+1
	Wend
	Return arr;
EndFunction

Function resize_array_array_String:String[][]( arr:String[][], leng:Int )
	Local i:Int = arr.length;
	arr = arr[..leng];
	If( leng<=i ) Return arr;

	For Local l:Int = 0 Until Len(arr)
		arr[l] = arr[l][..leng]
	Next
	
	While( i<leng )
		arr[0][i]="";
		i:+1
	Wend
	Return arr;
EndFunction

' From the BMax help: "If EndIndex is omitted, it defaults to the length of the string"
' It can't default to 0 since it ought to be able to slice a string such that [..0] -> ""
Function slice_string:String(arr:String, from:Int, term:Int = 2147483647)
	Local le:Int = arr.Length

	If from < 0
		from :+ le
		If from <0 Then from = 0
	Else If from > le
		from = le
	EndIf
	If term < 0
		term :+ le
	Else If term > le
		term = le
	EndIf

	' From the BMax help: "The length of the returned slice is always ( EndIndex - StartIndex ) elements long"
	' Thus, term = from should give a string of length 0
	If term = from Return ""
	If term < from Return arr
	Return Mid(arr, from + 1,  term - from)

EndFunction

Type ThrowableObject
	Method toString:String()
		Return "Uncaught Monkey Exception"
	EndMethod
EndType

' ***** End lang.bmx ******


