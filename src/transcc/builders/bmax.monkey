
Import builder

Class BMaxBuilder Extends Builder

	Method New( tcc:TransCC )
		Super.New( tcc )
	End

	Method Config:String()
		Local config:=New StringStack
		For Local kv:=Eachin GetConfigVars()
			config.Push "Const CFG_" + kv.Key + ":String=" + Enquote(kv.Value)
		Next
		Return config.Join( "~n" )
	End
	
	Method Enquote:String(str:String)
		'copied from bmxtranslator
		str=str.Replace( "~~","~~~~" )
		str=str.Replace( "~q","~~q" )
		str=str.Replace( "~n","~~n" )
		str=str.Replace( "~r","~~r" )
		str=str.Replace( "~t","~~t" )
		
		For Local i=0 Until str.Length
			If str[i]>=32 And str[i]<128 Continue
			Local t$,n=str[i]
			While n
				Local c=(n&15)+48
				If c>=58 c+=97-58
				t=String.FromChar( c )+t
				n=(n Shr 4) & $0fffffff
			Wend
			If Not t t="0"
			Select ENV_LANG
			Case "cpp"
				t="~qL~q\x"+t+"~qL~q"
			Default
				t="\u"+("0000"+t)[-4..]
			End
			str=str[..i]+t+str[i+1..]
			i+=t.Length-1
		Next
		Select ENV_LANG
		Case "cpp"
			str="L~q"+str+"~q"
		Default
			str="~q"+str+"~q"
		End
		Return str
	End
	
	Method IsValid:Bool()
		Select HostOS
		Case "winnt"
			If tcc.BMAX_PATH Return True
		Case "macos"
			If tcc.BMAX_PATH Return True
		End
		Return False
	End
	
	Method Begin:Void()
		ENV_LANG = "bmx"
		_trans = New BmxTranslator
	End
	
	Method MakeTarget:Void()
		
		CreateDataDir "data"
		
		Local main:String = LoadString("MonkeyGame.bmx")
		
		main = ReplaceBlock(main, "TRANSCODE", transCode, "~n'")
		main = ReplaceBlock(main, "CONFIG", Config(), "~n'")
		
		SaveString main, "MonkeyGame.bmx"

		If tcc.opt_build
			If tcc.opt_config = "debug"
				Execute tcc.BMAX_PATH + " makeapp -h -d -o MonkeyGame.debug MonkeyGame.bmx"
				Select HostOS
					Case "winnt"
						If tcc.opt_run
							Execute "MonkeyGame.debug.exe", False
						Endif
					Case "macos"
						If tcc.opt_run
							Execute "open MonkeyGame.debug.app", False
						Endif
				End
			Else
				Execute tcc.BMAX_PATH + " makeapp -h -a -r -v -t gui -o MonkeyGame MonkeyGame.bmx"
				Select HostOS
					Case "winnt"
						If tcc.opt_run
							Execute "MonkeyGame.exe", False
						Endif
					Case "macos"
						If tcc.opt_run
							Execute "open MonkeyGame.app", False
						Endif
				End
			EndIf
		EndIf
		
	End
	
End
