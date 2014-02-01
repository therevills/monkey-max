' ***** Start databuffer.bmx ******
Type BBDataBuffer
	Field _data:Byte[];
	Field _length:Int;
    
    Method _New( l:Int )
        _data = New Byte[ l ]
        _length = l;
    EndMethod
    
	Method Discard()
        _data = Null
        _length = 0
	EndMethod
	
	Method Length:Int()
		Return _length
	EndMethod

	Method PokeByte( addr:Int,value:Int )
        _data[ addr ] = value
	EndMethod
	
	Method PokeShort( addr:Int,value:Int )
        Local v:Short = value
        (Short Ptr Varptr _data)[ addr ] = v
	EndMethod
	
	Method PokeInt( addr:Int,value:Int )
        (Int Ptr Varptr _data)[ addr ] = value
	EndMethod
	
	Method PokeFloat( addr:Int,value:Float )
        (Float Ptr Varptr _data)[ addr ] = value
	EndMethod
	
	Method PeekByte:Int( addr:Int )
		Return _data[ addr ]
	EndMethod
	
	Method PeekShort:Int( addr:Int )
        Return (Short Ptr Varptr _data)[ addr ]
	EndMethod
	
	Method PeekInt:Int( addr:Int )
        Return (Int Ptr Varptr _data)[ addr ]
	EndMethod

	Method PeekFloat:Float( addr:Int )
        Return (Float Ptr Varptr _data)[ addr ]
	EndMethod

EndType
' ***** End databuffer.bmx ******


