Strict
Import mojo

Global tool:Image
Global toolPixels:Int[]
Global ground:Image
Global groundPixels:Int[]
       
Global loaded:Bool = False

Class MyApp Extends App
	Method OnCreate:Int()
		SetUpdateRate( 60 )
		ground = LoadImage( "level.png" )
		tool = LoadImage( "deform.png" )
		Return 0
	End
	Method OnUpdate:Int()
		If MouseDown()
			Local w:Int = ground.Width()
			Local h:Int = ground.Height()
			Local tw:Int = tool.Width()
			Local th:Int = tool.Height()

			'// offset mouse by tool size ( center tool )
			Local mx : Int = MouseX() - ( tw / 2.0 )
			Local my : Int = MouseY() - ( th / 2.0 )       

			'// calculate starting pixel index
			Local ti : Int = w * my + mx
			'// loop through tool pixels
			For Local y : Int = 0 Until th
				For Local x : Int = 0 Until tw
					'// if current location is on the screen
					If mx + x < DeviceWidth() And my + y < DeviceHeight()
						Local argb : Int
						'// get ground alpha
						argb = groundPixels[ ti + x ]
						Local ga : Int = ( argb Shr 24 ) & $ff
						'// get tool alpha
						argb = toolPixels[( y * tw ) + x ]
						Local ta : Int = ( argb Shr 24 ) & $ff                                 
						Local tr : Int = ( argb Shr 16 ) & $ff
						Local tg : Int = ( argb Shr 8 ) & $ff
						Local tb : Int = argb & $ff

						'// if neither are transparent write the tool to the ground pixels (draws white tool section on the ground)
						If ga <> 0 And ta <> 0
							'if current pixel of tool is white we want to cut this part out so use alpha color instead
							If tr = 255 And tg = 255 And tb = 255
								groundPixels[ ti + x ] = 0
								'if current pixel of tool is not white, e.g. black border, leave this as it is
							Else
								groundPixels[ ti + x ] = toolPixels[( y * tw ) + x ]
							End
						End
					End
				Next
				'// increment pixel index by the ground width to get the next rows starting index
				ti = ti + w
			Next
			'// update ground image
			ground.WritePixels( groundPixels, 0, 0, w, h )
		End
		Return 0
	End
	
	Method OnRender:Int() 
		'// Creates Manipulatable Images
		If loaded = False
			CreateCustomImages()
			loaded = True
		End

		Cls 64, 96, 160        
		'// Draws Images
		If ground <> Null Then DrawImage( ground, 0, 0 )
		If tool <> Null Then DrawImage( tool, MouseX(), MouseY() )
		Return 0
	End
End

Function Main:Int()
	New MyApp()
	Return 0
End

Function CreateCustomImages : Void()
	'// Create space for tool
	Local w : Int = tool.Width()
	Local h : Int = tool.Height()
	Local pixels : Int[ w * h ]
	Local img : Image

	Cls 128, 0, 255
	'// Grab tool sprite and mask background colour
	DrawImage tool, 0, 0
	ReadPixels( pixels, 0, 0, w, h )
	PixelArrayMask( pixels, 128, 0, 255 )
	img = CreateImage( w, h, 1, Image.MidHandle )
	img.WritePixels( pixels, 0, 0, w, h )
	tool = img
	toolPixels = pixels

	'// Create space for ground
	w = Min( ground.Width(), DeviceWidth() )
	h = Min( ground.Height(), DeviceHeight() )
	pixels = New Int[ w * h ]

	Cls 128, 0, 255
	'// Grab ground sprite and mask background colour
	DrawImage ground, 0, 0
	ReadPixels( pixels, 0, 0, w, h )
	PixelArrayMask( pixels, 128, 0, 255 )
	img = CreateImage( w, h )
	img.WritePixels( pixels, 0, 0, w, h )
	ground = img
	groundPixels = pixels   
End

'// Converts Mask Pixel Color to Transparent Pixel
Function PixelArrayMask : Void( pixels : Int[], mask_r : Int = 0, mask_g : Int = 0, mask_b : Int = 0 )
	For Local i : Int = 0 Until pixels.Length
		Local argb : Int = pixels[ i ]
		Local a : Int = ( argb Shr 24 ) & $ff
		Local r : Int = ( argb Shr 16 ) & $ff
		Local g : Int = ( argb Shr 8 ) & $ff
		Local b : Int = argb & $ff
		If a = 255 And r = mask_r And g = mask_g And b = mask_b
			a = 0
			argb = ( a Shl 24 ) | ( r Shl 16 ) | ( g Shl 8 ) | b
			pixels[ i ] = argb
		End
	Next
End