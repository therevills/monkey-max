' ***** Start databuffer.bmx ******
Type BBDataBuffer
	Field _data:Int;
	Field _length:Int;
	
	Method Discard()
	EndMethod
	
	Method Length:Int()
		Return _length
	EndMethod
	
	Method PokeByte()
	EndMethod
	
	Method PokeShort()
	EndMethod
	
	Method PokeInt()
	EndMethod
	
	Method PokeFloat()
	EndMethod
	
	Method PeekByte:Int()
		Return _length
	EndMethod
	
	Method PeekShort:Int()
		Return _length
	EndMethod
	
	Method PeekInt:Int()
		Return _length
	EndMethod
	
	Method PeekFloat:Float()
		Return _length
	EndMethod

EndType
' ***** End databuffer.bmx ******


