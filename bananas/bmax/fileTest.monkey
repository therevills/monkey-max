Strict

Import mojo

Function Main:Int()
	New Game()
	Return 0
End

Class Game Extends App
	Method OnCreate:Int()
		Local text:= LoadString("file1.txt")
		Print "text = " + text
		Return 0
	End
End