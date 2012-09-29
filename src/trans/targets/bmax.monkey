
Import target

Class BmaxTarget Extends Target

	Function IsValid()
		If FileType( "bmax" )<>FILETYPE_DIR Return False
		Return True
	End

	Method Begin()
		ENV_TARGET="bmax"
		ENV_LANG="bmx"
		_trans=New BmxTranslator
	End
	
	Method Config$()
		Local config:=New StringStack
		For Local kv:=Eachin _cfgVars
			'config.Push "CONST "+kv.Key+":String="+Enquote( kv.Value,"bmx" )
			config.Push "CONST "+kv.Key+":String="+LangEnquote( kv.Value)
		Next
		Return config.Join( "~n" )
	End
	
Method LangEnquote$( str$ )
	str=str.Replace( "\","\\" )
	str=str.Replace( "~q","\~q" )
	str=str.Replace( "~n","\n" )
	str=str.Replace( "~r","\r" )
	str=str.Replace( "~t","\t" )
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

Method BmxEnquote$( str$ )
	str=str.Replace( "~~","~~~~" )
	str=str.Replace( "~q","~~q" )
	str=str.Replace( "~n","~~n" )
	str=str.Replace( "~r","~~r" )
	str=str.Replace( "~t","~~t" )
	str=str.Replace( "~0","~~0" )
	str="~q"+str+"~q"
	Return str
End

Method BmxUnquote$( str$ )
	str=str[1..str.Length-1]
	str=str.Replace( "~~~~","~~z" )	'a bit dodgy - uses bad esc sequence ~z 
	str=str.Replace( "~~q","~q" )
	str=str.Replace( "~~n","~n" )
	str=str.Replace( "~~r","~r" )
	str=str.Replace( "~~t","~t" )
	str=str.Replace( "~~0","~0" )
	str=str.Replace( "~~z","~~" )
	Return str
End
	
	Method MakeTarget()
	
		'app data
		CreateDataDir "data"

'		Local meta$="var META_DATA=~q"+MetaData()+"~q;~n"
		
		'app code
		Local main$=LoadString( "MonkeyGame.bmx" )
		
		main=ReplaceBlock( main,"TRANSCODE",transCode, "~n'" )
'		main=ReplaceBlock( main,"METADATA",meta )
		main=ReplaceBlock( main,"CONFIG",Config(), "~n'" )

'		main=ReplaceBlock( main,"${TRANSCODE_BEGIN}","${TRANSCODE_END}",transCode )
		
		SaveString main,"MonkeyGame.bmx"
		
		If OPT_ACTION>=ACTION_BUILD

			Select ENV_CONFIG
				Case "release"
					Execute BMAX_PATH+" makeapp -a -r -v -t gui MonkeyGame.bmx"
				Case "debug"
					Execute BMAX_PATH+" makeapp -d MonkeyGame.bmx"
			End

			If OPT_ACTION>=ACTION_RUN
				Execute "MonkeyGame.exe",False
			Endif
		Endif
	End	
End
