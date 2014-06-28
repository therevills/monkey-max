' ***** Start mojo.bmax.bmx ******

Global _ix:Float, _iy:Float, _jx:Float, _jy:Float
Global _color:Int = $ffffffff
Global _alpha:Float = 1.0

' Helper functions
Function DrawTexturedPoly( image:TImage,xyuv#[],frame:Int=0, vertex:Int = -1)
	Local handle_x#,  handle_y#
	GetHandle handle_x#,  handle_y#
	Local origin_x#,  origin_y#
	GetOrigin origin_x#,  origin_y#	
    
	Assert Image, "Image not found"

	Local D3DDriver9:TD3D9Max2DDriver = TD3D9Max2DDriver(_max2dDriver)
	If D3DDriver9 Then 
		DrawTexturedPolyD3D9 ..
			D3DDriver9,..
			 TD3D9ImageFrame(image.Frame(frame)), ..
			 xyuv, handle_x, handle_y, origin_x,origin_y, vertex*4
		Return
	End If	
	Local D3DDriver:TD3D7Max2DDriver = TD3D7Max2DDriver(_max2dDriver)
	If D3DDriver Then 
		DrawTexturedPolyD3D ..
			D3DDriver,..
			 TD3D7ImageFrame(image.Frame(frame)), ..
			 xyuv, handle_x, handle_y, origin_x,origin_y, vertex*4
		Return
	End If
	Local  OGLDriver:TGLMax2DDriver = TGLMax2DDriver(_max2dDriver)
	If OGLDriver Then
			DrawTexturedPolyOGL ..
				OGLDriver,..
				 TGLImageFrame(image.Frame(frame)), ..
				 xyuv, handle_x, handle_y, origin_x,origin_y,  vertex*4
		Return
	End If
End Function

Function DrawTexturedPolyD3D9( Driver:TD3D9Max2DDriver,  Frame:TD3D9ImageFrame,xyuv#[],handlex#,handley#,tx#,ty# , vertex:Int)
	If xyuv.length<6 Return
	Local segs:Int=xyuv.length/4
	Local len_:Int = Len(xyuv)
    
	If vertex > - 1 Then
		segs = vertex / 4
		len_ = vertex
	End If
	Local uv#[] = New Float[segs*6] ' 6

	Local c:Int Ptr=Int Ptr(Float Ptr(uv))
	
	Local ii:Int = 0
	For Local i:Int=0 Until len_ Step 4
		Local x# =  xyuv[i+0]+handlex
		Local y# =  xyuv[i+1]+handley
		uv[ii+0] =  x*_ix+y*_iy+tx
		uv[ii+1] =  x*_jx+y*_jy+ty 
		uv[ii+2] =  0  ' *********** THIS IS THE Z-COORDINATE
		c[ii+3] = _color
		uv[ii+4] =  xyuv[i+2]
		uv[ii+5] =  xyuv[i+3]
		ii:+6
	Next
    
'    Print uv[0] + " " + uv[1] + " " + uv[2] + " " + uv[3] + " " + uv[4] + " " + uv[5]

    Frame.Draw 0,0,0,0,0,0,0,0,0,0	'KLUDGE - Note to Mr. Sibly an EnableTex function
    _d3dDev.DrawPrimitiveUP( D3DPT_TRIANGLEFAN,segs-2,uv,24 )
End Function

Function DrawTexturedPolyD3D( Driver:TD3D7Max2DDriver,  Frame:TD3D7ImageFrame,xyuv#[],handlex#,handley#,tx#,ty# , vertex:Int)
	If xyuv.length<6 Return
	Local segs:Int=xyuv.length/4
	Local len_:Int = Len(xyuv)
	
	If vertex > - 1 Then
		segs = vertex / 4
		len_ = vertex
	End If
	Local uv#[] = New Float[segs*6] ' 6

	Local c:Int Ptr=Int Ptr(Float Ptr(uv))
	
	Local ii:Int = 0
	For Local i:Int=0 Until len_ Step 4
		Local x# =  xyuv[i+0]+handlex
		Local y# =  xyuv[i+1]+handley
		uv[ii+0] =  x*Driver.ix+y*Driver.iy+tx
		uv[ii+1] =  x*Driver.jx+y*Driver.jy+ty 
		uv[ii+2] =  0  ' *********** THIS IS THE Z-COORDINATE
		c[ii+3] = Driver.DrawColor
		uv[ii+4] =  xyuv[i+2]
		uv[ii+5] =  xyuv[i+3]
		ii:+6
	Next

    Print uv[0] + " " + uv[1] + " " + uv[2] + " " + uv[3] + " " + uv[4] + " " + uv[5] + " " + uv[6]

	Driver.SetActiveFrame Frame
	Driver.device.DrawPrimitive(D3DPT_TRIANGLEFAN,D3DFVF_XYZ| D3DFVF_DIFFUSE | D3DFVF_TEX1,uv,segs,0)
End Function

Function DrawTexturedPolyOGL (Driver:TGLMax2DDriver, Frame:TGLImageFrame, xy#[],handle_x#,handle_y#,origin_x#,origin_y#, vertex:Int) 
	Private
	Global TmpImage:TImage
	Public
	
	If xy.length<6 Return
	
	Local rot#  = GetRotation()
	Local tform_scale_x#, tform_scale_y#
	GetScale tform_scale_x, tform_scale_y
	
	Local s#=Sin(rot)
	Local c#=Cos(rot)
	Local ix#= c*tform_scale_x
	Local iy#=-s*tform_scale_y
	Local jx#= s*tform_scale_x
	Local jy#= c*tform_scale_y
	
	glBindTexture GL_TEXTURE_2D, Frame.name
	glEnable GL_TEXTURE_2D
	
	glBegin GL_POLYGON
	For Local i:Int=0 Until Len xy Step 4
		If vertex > -1 And i >= vertex Then Exit
		Local x#=xy[i+0]+handle_x
		Local y#=xy[i+1]+handle_y
		Local u#=xy[i+2]
		Local v#=xy[i+3]
		glTexCoord2f u,v
		glVertex2f x*ix+y*iy+origin_x,x*jx+y*jy+origin_y
	Next
	glEnd
	If Not tmpImage Then tmpImage = CreateImage(1,1)
	DrawImage tmpImage, -100, - 100 ' Chtob zbit' flag texturi
End Function

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
        _alpha = a
		_color=(Int(255*_alpha) Shl 24)|(_color&$ffffff)
		Return 0
	EndMethod
	
	Method SetColor:Int(r:Int, g:Int, b:Int)
		.SetColor(r, g, b)
		_color=(_color&$ff000000)|(r Shl 16)|(g Shl 8)|b
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

	Method DrawPoly2:Int(vertices:Float[],surface:gxtkSurface,x:Float,y:Float)
        _ix = ix
        _iy = iy
        _jx = jx
        _jy = jy
        DrawTexturedPoly(surface.image, vertices )
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
		
		Local sound:TSound
		If flags = 1
			'looping
			'load sound with looping
			sound = BBBMaxGame.BMaxGame().LoadSample( path,1 )
			If Not sound Then Return -1
			
			'create a monkey sample object
			music = New gxtkSample
			music.path = path
			music.soundLooping = sound
			
			'play on music channel (with looping)
			PlaySample(music, MUSIC_CHANNEL, 1)
		Else
			'not looping
			'load sound without looping
			sound = BBBMaxGame.BMaxGame().LoadSample( path,0 )
			If Not sound Then Return -1
			
			'create a monkey sample object
			music = New gxtkSample
			music.path = path
			music.sound = sound
			
			'play on music channel (non looping)
			PlaySample(music, MUSIC_CHANNEL, 0)
		EndIf
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
			chan.State = 0
			chan.sample = Null
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
		
		'pause channel if it is already playing
		If chan.State <> 0 Then chan.channel.SetPaused(True)
		
		'update other runtime bits in channel
		chan.loops = (flags = 1)
		chan.State = 1
		
		'check what action to take
		If chan.loops
			'check if we need to load looping version
			If sample.soundLooping = Null sample.soundLooping = BBBMaxGame.BMaxGame().LoadSample(sample.path,1)
			
			'set which sample is playing in channel
			chan.sample = sample
			
			'play the sound
			PlaySound( sample.soundLooping, chan.channel )
		Else
			'check if we need to load non looping version
			If sample.sound = Null sample.sound = BBBMaxGame.BMaxGame().LoadSample(sample.path,0)
			
			'set which sample is playing in channel
			chan.sample = sample
			
			'play the sound
			PlaySound( sample.sound, chan.channel )
		EndIf
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
		
		'choose where to store this loaded sound
		If flags = 1
			'is a looping sound
			sample.soundLooping = sound
		Else
			'is not looping (really no other way to switch a sample to loop/non-loop????)
			sample.sound = sound
		EndIf
		
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
	Field soundLooping:TSound
	Field path:String
	
	Method Discard()
		Self.sound = null
	EndMethod
EndType
' ***** End mojo.bmax.bmx ******


