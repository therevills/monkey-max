Strict

#BMAX_WINDOW_TITLE="Mojo Test"
#BMAX_WINDOW_WIDTH=1024
#BMAX_WINDOW_HEIGHT=768
#BMAX_WINDOW_FULLSCREEN=False
#MOJO_IMAGE_FILTERING_ENABLED=True
#MOJO_AUTO_SUSPEND_ENABLED=True

Import mojo

Global game:MyGame

Function Main:Int()
	game = New MyGame
	Return 0
End

Class MyGame Extends App
	Field sound:Sound
	Field soundLoop:Int = True
	Field state:String
	
	Method OnSuspend:Int()
		Print "OnSuspend"
		Return 0
	End
	
	Method OnResume:Int()
		Print "OnResume"
		Return 0
	End
	
	Method OnLoading:Int()
		Print "OnLoading"
		Return 0
	End
	
	Method OnCreate:Int()
		SetUpdateRate 60
		sound = LoadSound("sound.ogg")
		Return 0
	End
	
	Method OnUpdate:Int()
		If KeyHit(KEY_SPACE) Then
			Print "SPACE MAN"
			soundLoop = Not soundLoop
			PlaySound(sound, 0, soundLoop)
		Endif
		Return 0		
	End
	
	Method OnRender:Int()
		Cls(100,100,100)
		Return 0
	End
End