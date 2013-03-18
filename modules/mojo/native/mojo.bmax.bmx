' ***** Start mojo.bmax.bmx ******
'graphics objects
Type gxtkGraphics
	Field ix:Float=1,iy:Float,jx:Float,jy:Float=1,tx:Float,ty:Float
	Field sx:Float=1,sy:Float=1,rot:Float=0
	
	'helper
	Method TransX:Float(X:Float, Y:Float)
		Return ix*x + jx*y + tx
	EndMethod
	
	Method TransY:Float(x:Float, y:Float)
		Return iy*x + jy*y + ty
	EndMethod
	
	'propeties
	Method Width:Int()
		Return GraphicsWidth()
	EndMethod
	
	Method Height:Int()
		Return GraphicsHeight()
	EndMethod
	
	'events
	Method BeginRender:Int()
		
		Return 1
	EndMethod
	
	Method EndRender()
		Flip
	EndMethod
	
	Method DiscardGraphics()
	End Method
	
	'surface creation/loading
	Method LoadSurface:gxtkSurface(path:String)
		'get game load image
		path = BBBMaxGame.BMaxGame().PathToFilePath(path)
		Local image:TImage = BBBMaxGame.BMaxGame().LoadBitmap(path)
		If image = Null Return Null
		
		'create surface and attach iamge to it
		Local gs:gxtkSurface = New gxtkSurface
		gs.image = image
		
		'return the surface
		Return gs
	EndMethod
	
	Method CreateSurface:gxtkSurface( Width:Int, Height:Int )
		Local image:TImage = CreateImage(Width, Height,1,-1)
		Local surface:gxtkSurface = New gxtkSurface
		surface.image = image
		Return surface
	EndMethod
	
	'commands
	Method Cls:Int(r:Int = 0, g:Int = 0, b:Int = 0)
		SetClsColor(r, g, b)
		.Cls()
		Return 0
	EndMethod
	
	Method SetAlpha:Int(a:Float)
		.SetAlpha(a)
		Return 0
	EndMethod
	
	Method SetColor:Int(r:Int, g:Int, b:Int)
		.SetColor(r, g, b)
		Return 0
	EndMethod
	
	Method SetMatrix:Int(ix:Float,iy:Float,jx:Float,jy:Float,tx:Float,ty:Float)
		Self.ix = ix
		Self.iy = iy
		Self.jx = jx
		Self.jy = jy
		Self.tx = tx
		Self.ty = ty
		sx = Sqr(ix*ix+iy*iy)
		sy = Sqr(jx*jx+jy*jy)
		rot = Atan2( iy, ix )
		If ix < 0 Then
			sx = -sx
			rot :+ 180
		EndIf
		If jy < 0 Then sy = -sy
		SetTransform( rot, sx, sy )
		Return 0
	EndMethod
	
	Method SetScissor:Int(X:Int, Y:Int, w:Int, h:Int)
		SetViewport(x, y, w, h) ' NOT TESTED!
		Return 0
	EndMethod
	
	Method SetBlend:Int(blend:Int)
		Select blend
			Case 0
				.SetBlend( ALPHABLEND )
			Case 1
				.SetBlend( LIGHTBLEND )
		EndSelect
		Return 0
	EndMethod
	
	'drawing
	Method DrawPoint:Int(X:Float, Y:Float)
		Local nx:Float = TransX(x,y)
		Local ny:Float = TransY(x,y)
		Plot nx, ny
	EndMethod
	
	Method DrawRect:Int( X:Float, Y:Float, w:Float, h:Float )
		Local nx:Float = TransX(x,y)
		Local ny:Float = TransY(x,y)
		.DrawRect(nx, ny, w, h)
		Return 0
	EndMethod
	
	Method DrawLine:Int( x1:Float,y1:Float,x2:Float,y2:Float )
		Local nx1:Float = TransX(x1,y1)
		Local ny1:Float = TransY(x1,y1)
		Local nx2:Float = TransX(x2,y2)
		Local ny2:Float = TransY(x2,y2)
		' Need to reset transform so that BlitzMax doesn't try to apply rotation
		SetTransform( 0, 1, 1 )
		.DrawLine(nx1, ny1, nx2, ny2)
		SetTransform( rot, sx, sy )
		Return 0
	EndMethod
	
	Method DrawOval:Int( x:Float, y:Float, w:Float, h:Float )
		Local nx:Float = TransX(x,y)
		Local ny:Float = TransY(x,y)
		.DrawOval(nx, ny, w, h)
		Return 0
	EndMethod
	
	Method DrawPoly:Int(vertices:Float[])
		' setting the origin to use the current rotation translation
		SetOrigin(TransX(0,0), TransY(0,0))
		.DrawPoly( vertices )
		SetOrigin(0, 0)
		Return 0
	EndMethod
	
	Method DrawSurface:Int(surface:gxtkSurface,X:Float,Y:Float)
		Local nx:Float = TransX(x,y)
		Local ny:Float = TransY(x,y)
		DrawImage(surface.image, nx, ny, 0)
		Return 0
	EndMethod
	
	Method DrawSurface2:Int(surface:gxtkSurface,x:Float,y:Float, srcx:Int, srcy:Int, srcw:Int, srch:Int )
		Local nx:Float = TransX(x,y)
		Local ny:Float = TransY(x,y)
		DrawSubImageRect(surface.image, nx, ny, srcw, srch, srcx, srcy, srcw, srch)		
		Return 0
	EndMethod

	'pixel ops
	Method ReadPixels:Int( Pixels:Int[], X:Int, Y:Int, Width:Int, Height:Int, offset:Int, pitch:Int )
		Local pix:TPixmap = GrabPixmap(x, y, width, height)
		Local px:Int
		Local py:Int
		Local j:Int = offset
		Local argb:Int
		
		For py = 0 Until height
			For px = 0 Until width
				pixels[j] = pix.ReadPixel(px, py)
				j:+1
			Next
			j:+pitch - width
		Next
		
		Return 0
	EndMethod
	
	Method WritePixels2:Int( surface:gxtkSurface, pixels:Int[], x:Int, y:Int, width:Int, height:Int, offset:Int, pitch:Int )
		Local pix:TPixmap = LockImage(surface.image)
		Local px:Int
		Local py:Int
		Local j:Int = offset
		Local argb:Int
		
		For py = 0 Until height
			For px = 0 Until width
				WritePixel(pix, px, py, pixels[j])
				j:+1
			Next
			j:+pitch - width
		Next
		
		UnlockImage(surface.image)
		Return 0
	EndMethod
EndType

Type gxtkSurface
	Field image:TImage
	
	Method Discard:Int()
		image = Null
	End Method
	
	Method Width:Int()
		Return image.Width
	End Method
	
	Method Height:Int()
		Return image.Height
	End Method
	
	Method OnUnsafeLoadComplete:Int()
		Return True
	End Method
End Type

'audio objects
Type gxtkAudio
	Field amusicState:Int = 0
	Field channels:gxtkChannel[] = New gxtkChannel[33]
	Const MUSIC_CHANNEL:Int = 32
	Field music:gxtkSample
	
	'constructor/destructor
	Method New()
		For local i:Int = 0 To 33 - 1
			channels[i] = New gxtkChannel
			channels[i].channel = AllocChannel()
		Next
	EndMethod
	
	'events
	Method Suspend()
		For Local i:Int = 0 To 33 - 1
			Local chan:gxtkChannel = channels[i]
			If chan.state = 1 Then
				chan.channel.SetPaused(True)
			EndIf
		Next
	EndMethod

	Method Resume()
		For Local i:Int = 0 To 33 - 1
			Local chan:gxtkChannel = channels[i]
			If chan.state = 1 Then
				chan.channel.SetPaused(False)
			EndIf
		Next
	EndMethod
	
	'api
	Method MusicState:Int()
		' Monkey Docs: 	0 if the music is currently stopped
		'				1 if the music is currently playing
		'				-1 if the music state cannot be determined

		Local chan:gxtkChannel = channels[MUSIC_CHANNEL]
		If chan.channel <> Null Then
			If ChannelPlaying(chan.channel) Then Return 1 Else Return 0
		EndIf
		
		Return -1
	EndMethod
	
	Method PlayMusic:Int( path:String, flags:Int=0 )
		StopMusic()
		channels[MUSIC_CHANNEL].channel = AllocChannel()
		path = BBBMaxGame.BMaxGame().PathToFilePath(path)
		
		'load the music as a sample, really?
		Local musicSound:TSound = BBBMaxGame.BMaxGame().LoadSample( path,flags )
		If Not musicSound Then Return -1
		
		'create a monkey sample object
		music = New gxtkSample
		music.sound = musicSound
		music.path = path
		music.Loop = flags
		
		'play the sample on teh music channel
		PlaySample(music, MUSIC_CHANNEL, flags)
		Return 0
	EndMethod
	
	Method StopMusic:Int()
		StopChannel( MUSIC_CHANNEL )
		
		If music Then
			music.Discard()
			music = null
		EndIf
		Return 0
	EndMethod
	
	Method ChannelState:int( channel:int )
		' Monkey Docs: 	0 if the channel is currently stopped
		'				1 if the channel is currently playing
		'				2 if the channel is currently paused
		'				-1 if the channel state cannot be determined
		Local chan:gxtkChannel = channels[channel]
		If chan.channel <> Null Then
			If ChannelPlaying(chan.channel) Then Return 1 Else Return 0
		EndIf
		
		Return -1
	EndMethod
	
	Method StopChannel( channel:Int )
		Local chan:gxtkChannel = channels[channel]
		
		If chan.state <> 0
			chan.channel.Stop()
			chan.state = 0
		EndIf
	EndMethod
	
	Method PauseChannel:Int( channel:Int)
		Local chan:gxtkChannel = channels[channel]
		chan.channel.SetPaused(True)
		Return 0
	EndMethod
	
	Method ResumeChannel:Int( channel:Int)
		Local chan:gxtkChannel = channels[channel]
		chan.channel.SetPaused(False)
		Return 0
	EndMethod
	
	Method PlaySample( sample:gxtkSample, channel:Int, flags:Int )
		'get and modify channel
		Local chan:gxtkChannel = channels[channel]
		If chan.state <> 0 Then chan.channel.SetPaused(True)
		chan.sample = sample
		chan.loops = (flags = 1)
		chan.state = 1
		
		'if looping, we need to reload the sound with the looping flag
		If chan.loops And sample.Loop = False
			'inject new sound into this sample
			sample.sound = BBBMaxGame.BMaxGame().LoadSample(sample.path,flags)
			sample.Loop = flags
		EndIf
	
		'play the sound
		PlaySound( sample.sound, chan.channel )
	EndMethod

	Method SetPan( channel:Int, pan:Float )
		Local chan:gxtkChannel = channels[channel]
		chan.channel.SetPan(pan)
	EndMethod

	Method SetRate( channel:Int, rate:Float )
		Local chan:gxtkChannel = channels[channel]
		chan.channel.SetRate(rate)
	EndMethod

	Method PauseMusic:Int()
		Local chan:gxtkChannel = channels[MUSIC_CHANNEL]
		chan.channel.SetPaused(True)
		Return 0
	EndMethod

	Method ResumeMusic:Int()
		Local chan:gxtkChannel = channels[MUSIC_CHANNEL]
		chan.channel.SetPaused(False)
		Return 0
	EndMethod

	Method SetMusicVolume:Int( volume:Float )
		SetVolume( MUSIC_CHANNEL, volume )
		Return 0
	EndMethod

	Method SetVolume:Int( channel:Int, volume:Float )
		Local chan:gxtkChannel = channels[channel]
		chan.channel.SetVolume(volume)
		Return 0
	EndMethod
	
	Method LoadSample:gxtkSample( path:String,flags:Int=0 )
		'attempt to load blitzmax sound
		path = BBBMaxGame.BMaxGame().PathToFilePath(path)
		Local sound:TSound = BBBMaxGame.BMaxGame().LoadSample(path,flags)
		If sound = Null Return Null
		
		'create monkey sample
		Local sample:gxtkSample = New gxtkSample
		sample.path = path
		sample.sound = sound
		sample.Loop = flags
		Return sample
	EndMethod
EndType

Type gxtkChannel
	Field channel:TChannel
	Field sample:gxtkSample
	Field loops:int
	Field State:Int
	
	Method New()
		channel = New TChannel
	EndMethod
EndType

Type gxtkSample
	Field sound:TSound
	Field path:String
	Field loop:Int
	
	Method Discard()
		Self.sound = null
	EndMethod
EndType
' ***** End mojo.bmax.bmx ******


