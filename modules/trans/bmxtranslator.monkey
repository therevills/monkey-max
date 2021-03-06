
' Module trans.bmxtranslator
'
' Placed into the public domain 24/02/2011.
' No warranty implied; use at your own risk.

Import trans

Const KLUDGE_INTERFACES:=True

'To be used after reflection/semant immediately before translate
'
Function KludgeInterfaces( app:AppDecl )
	'skn3: so in kludge interface we build a SUPER "_Object" that contains all interface methods
	'each user Class in monkey extends from this super "_Object" so we need to make sure that
	'overriding methods correctly determin if they need to be munged... i think?
	
	'find Object decl
	Local odecl:ClassDecl
	For Local decl:=Eachin app.allSemantedDecls
		Local cdecl:=ClassDecl( decl )
		If cdecl And cdecl.munged="Object"
			odecl=cdecl
			Exit
		Endif
	Next
	
	'create Kludge class
	'
	Local idecl:=New ClassDecl
	idecl.ident="_Object"
	idecl.munged="_Object"
	idecl.attrs=DECL_SEMANTED
	idecl.superTy=Type.objectType
	idecl.superClass=odecl
	idecl.objectType=New ObjectType( idecl )

	Local inull:=New ConstExpr
	inull.exprType=idecl.objectType
	
	'find all interfaces/methods
	'
'	Local ifaces:=New List<ClassDecl>
	Local ifaces:=New StringSet
	Local icasts:=New StringMap<FuncDecl>
	Local imethods:=New StringMap<List<FuncDecl>>

	For Local decl:=Eachin app.Semanted
	
		Local cdecl:=ClassDecl( decl )
		
		If cdecl And cdecl.IsInterface()

			If ifaces.Contains( cdecl.ident ) Continue
			ifaces.Insert cdecl.ident

			'create 'To' casting method...
			'
			Local fdecl:=New FuncDecl
			fdecl.ident="_To"+cdecl.ident
			fdecl.munged="_To"+cdecl.ident
			fdecl.attrs=DECL_SEMANTED|FUNC_METHOD
			fdecl.retType=idecl.objectType
			idecl.InsertDecl fdecl
			icasts.Set fdecl.munged,fdecl
			fdecl.AddStmt New ReturnStmt( inull )
				
			For Local decl:=Eachin cdecl.Semanted
				Local fdecl:=FuncDecl( decl )
				If fdecl
					Local list:=imethods.Get( fdecl.ident )
					If list
						Local found:=False
						For Local fdecl2:=Eachin list
							If fdecl.EqualsFunc( fdecl2 )
								found=True
								Exit
							Endif
						Next
						If found Continue
					Else
						list=New List<FuncDecl>
						imethods.Set fdecl.ident,list
					Endif
					'
					list.AddLast fdecl
					'					
					'move decl to Kludge object...
					'
					fdecl.scope=Null
					idecl.InsertDecl fdecl
					fdecl.attrs&=~DECL_ABSTRACT
					If Not VoidType(fdecl.retType)
						Local expr:=New ConstExpr
						expr.exprType=fdecl.retType
						fdecl.AddStmt New ReturnStmt(expr)
					EndIf
					'
				Endif
			Next
		Endif
	Next
	
	'update method overrides
	'
	For Local decl:=Eachin app.Semanted
	
		Local cdecl:=ClassDecl( decl )
		
		If cdecl And Not cdecl.IsInterface()
		
			'change super class to kludge class
			'
			If cdecl.superClass=odecl
				cdecl.superClass=idecl
			Endif
			
			'create cast ops for implemented interfaces
			'
			Local mdone:=New StringSet
			For Local iface:=Eachin cdecl.implmentsAll
				If mdone.Contains( iface.ident ) Continue
				mdone.Insert iface.ident
				Local fdecl:=New FuncDecl
				fdecl.ident="_To"+iface.ident
				fdecl.munged="_To"+iface.ident
				fdecl.attrs=DECL_SEMANTED|FUNC_METHOD
				fdecl.retType=idecl.objectType
				fdecl.overrides=icasts.Get( fdecl.munged )
				cdecl.InsertDecl fdecl
				Local expr:=New SelfExpr
				expr.exprType=cdecl.objectType
				fdecl.AddStmt New ReturnStmt( expr )
			Next
			
			'fix method overrides
			'
			For Local decl:=Eachin cdecl.Semanted
				Local fdecl:=FuncDecl( decl )
				If fdecl And fdecl.IsMethod() And Not fdecl.overrides
					Local list:= imethods.Get(fdecl.ident)
					If list
						For Local fdecl2:=Eachin list
							If fdecl.EqualsFunc(fdecl2)
								fdecl.overrides = fdecl2
								Exit
							Endif
						Next
						
						'if none found then we need to search again for matching name?
						'is this ok, seems to work?
						If Not fdecl.overrides
							For Local fdecl2:= EachIn list
								If fdecl.ident = fdecl2.ident and fdecl.EqualsArgs(fdecl2)
									fdecl.overrides = fdecl2
									Exit
								Endif
							Next
						EndIf
					EndIf
				Endif
			Next
		Endif
	Next
	
	app.mainModule.InsertDecl idecl
	app.Semanted.AddFirst idecl
	app.allSemantedDecls.AddFirst idecl
	
End

Class BmxTranslator Extends CTranslator

	Method TransType$( ty:Type )
		If VoidType( ty ) Return "Int" ' no Void type in BlitzMax
		If BoolType( ty ) Return "Int"
		If IntType( ty ) Return "Int"
		If FloatType( ty ) Return "Float"
		If StringType( ty ) Return "String"
		If ArrayType( ty ) Return TransType( ArrayType(ty).elemType )+"[]"
		If ObjectType( ty )
			Local cdecl:=ty.GetClass()
			If KLUDGE_INTERFACES
				If cdecl.IsInterface() Or cdecl.munged="Object" Return "_Object"
			Endif
			Return cdecl.munged
		Endif
		InternalErr("TransType")
	End
	
	Method TransValue$( ty:Type,value$ )
'		Print "value = "+value
		If value
			If IntType( ty ) And value.StartsWith( "$" ) Return "0x"+value[1..]
			If BoolType( ty ) Return "true"
			If NumericType( ty ) Return value
			If StringType( ty ) Return Enquote( value )
		Else
			If BoolType( ty ) Return "false"
			If NumericType( ty ) Return "0"
			If StringType( ty ) Return "~q~q"
			If ArrayType( ty ) 
				Local elemTy:=ArrayType( ty ).elemType
				Local t$="[0]"
				Local arrayOfArrays?=False
				Local count%=0
				Local at$=""
				While ArrayType( elemTy )
					count+=1
					elemTy=ArrayType( elemTy ).elemType
					arrayOfArrays=True
				Wend
			'	Print "count = "+count
				For Local i:Int = 0 Until count
					if i <> count-1 Then
						at+="[]"
					else
						at+="[0]"
					End
				Next
			'	Print "at = "+at
				
				If arrayOfArrays
					t = "[]"+at
				Else
					t = t
				End
				
				Return "New "+TransType( elemTy )+t
								
			Endif
'			If ObjectType( ty ) Return "null"
			If ObjectType( ty ) Return TransType( ty ) + "(null)"
		Endif
		InternalErr("TransValue")
	End
	
	Method TransValDecl$( decl:ValDecl )
		Return decl.munged+":"+TransType( decl.type )
	End
	
	Method TransArgs$( args:Expr[] )
		Local t$
		For Local arg:=Eachin args
			If t t+=","
			t+=arg.Trans()
		Next
		Return Bra(t)
	End
	
	'***** Utility *****

	Method TransLocalDecl$( munged$,init:Expr )
		Return "local "+munged+":"+TransType( init.exprType )+"="+init.Trans()
	End

	Method EmitEnter( func:FuncDecl )
		Emit "pushErr();"
	End
	
	Method EmitSetErr( info$ )
		Emit "_errInfo=~q"+info.Replace( "\","/" )+"~q;"
	End
	
	Method EmitLeave()
		Emit "popErr();"
	End

	'***** Declarations *****
	Method TransStatic:String(decl:Decl)
		If decl.IsExtern() And ModuleDecl( decl.scope )
			Return decl.munged
		Else If _env And decl.scope And decl.scope=_env.ClassScope()
			Return decl.scope.munged+"."+decl.munged
		Else If ClassDecl( decl.scope )
			Return decl.scope.munged+"."+decl.munged
		Else If ModuleDecl( decl.scope )
			Return decl.munged
		Endif
		InternalErr("TransStatic")
	End

	Method TransTemplateCast$( ty:Type,src:Type,expr$ )
		If ty.ActualType().EqualsType( src.ActualType() ) Return expr
		
		If Not ObjectType( src ) Err "Can't convert from "+src.ToString()+" to "+ty.ToString()

		'Return Bra( expr+" as "+TransType(ty) )
		Return TransType(ty)+Bra(expr)
	End

	Method TransGlobal$( decl:GlobalDecl )
		Return TransStatic( decl )
	End
	
	Method TransField$( decl:FieldDecl,lhs:Expr )
		Local t_lhs$="self"
		If lhs
			t_lhs=TransSubExpr( lhs )
		Endif
		Return t_lhs+"."+decl.munged
	End
		
	Method TransFunc$( decl:FuncDecl,args:Expr[],lhs:Expr )
		If decl.IsMethod()
			Local t_lhs$="self"
			If lhs
				t_lhs=TransSubExpr( lhs )
			Endif
			Return t_lhs+"."+decl.munged+TransArgs( args )
		Endif
		Return TransStatic( decl )+TransArgs( args )
	End
	
	Method TransSuperFunc:String(decl:FuncDecl, args:Expr[])
		Return "super." + decl.munged + TransArgs(args)
	End
	
	'***** Expressions *****

	Method TransConstExpr$( expr:ConstExpr )
		Return TransValue( expr.exprType,expr.value )
	End

	Method TransNewObjectExpr$( expr:NewObjectExpr )
		Local t$
		If expr.classDecl.munged<>"Object"
			t="(new "+expr.classDecl.munged+")"
		Else
			t="(new "+expr.classDecl.munged+"[0])"
		End
		If expr.ctor t+="."+expr.ctor.munged+TransArgs( expr.args )
		Return t
	End

	Method TransNewArrayExpr$( expr:NewArrayExpr )
		Local texpr$=expr.expr.Trans()
'		Print "TransNewArrayExpr texpr="+texpr
		Local elemTy:=ArrayType( expr.exprType ).elemType
		'
	'	If StringType( elemTy ) Return "bb_std_lang.stringArray"+Bra(texpr)
		'		
		Local t$="["+texpr+"]"
		Local tmp$, i%=0
		Local ma?=False
		While ArrayType( elemTy )
			elemTy=ArrayType( elemTy ).elemType
			tmp = t
			If i = 0
				t = "new " + TransType( elemTy ) + "[]"
				t += tmp
			Endif
			i += 1
			ma = True
		Wend
		' TEST THIS BIT LATER!!!!!!!!!!!!!!!!!!!!!!!!<!<!>!<!><!

		If ma
			Return t
		Else
			Return "new "+TransType( elemTy )+t
		End		
	End

	Method TransSelfExpr$( expr:SelfExpr )
		Return "self"
	End
	
	Method TransCastExpr$( expr:CastExpr )
		Local dst:=expr.exprType
		Local src:=expr.expr.exprType
		Local texpr$=Bra( expr.expr.Trans() )
		
		If BoolType( dst )
			If BoolType( src ) Return texpr
			If IntType( src ) Return Bra( texpr )
			If FloatType( src ) Return Bra( texpr )
			If StringType( src ) Return Bra( texpr )
			If ArrayType( src ) Return Bra( texpr)
			If ObjectType( src ) Return Bra( texpr )
		Else If IntType( dst )
			If BoolType( src ) Return Bra( texpr )
			If IntType( src ) Return texpr
			If FloatType( src ) Return "Int("+Bra( texpr )+")"
'			If StringType( src ) Return Bra( texpr )
			If StringType( src ) Return "Int("+Bra( texpr )+")"
		Else If FloatType( dst )
'			If NumericType( src ) Return texpr
			If NumericType( src ) Return "Float("+texpr+")"
			'If StringType( src ) 	Return texpr
			If StringType( src ) Return "Float("+Bra( texpr )+")"
		Else If StringType( dst )
			If NumericType( src ) Return "String("+texpr+")"
			If StringType( src )  Return texpr
		Else If ObjectType( dst ) And ObjectType( src )
			If src.GetClass().ExtendsClass( dst.GetClass() )
				Return texpr
			Else If KLUDGE_INTERFACES And dst.GetClass().IsInterface()
				Return texpr+"._To"+dst.GetClass().ident+"()"
			Else
				Return Bra( "(" + TransType( dst ) + ")(" + texpr + ")" )
			Endif
		
		Endif
#rem	
		
		If src.GetClass().ExtendsClass( dst.GetClass() )
			Return texpr
		Else If dst.GetClass().ExtendsClass( src.GetClass() )
 			'
			If KLUDGE_INTERFACES And dst.GetClass().IsInterface()
				Return texpr+"._To"+dst.GetClass().ident+"()"
			Endif
			'

'			Return Bra( texpr + " as "+TransType( dst ) )
			Return Bra( "(" + TransType( dst ) + ")(" + texpr + ")" )
		Endif
#end
		Err "BMax translator can't convert "+src.ToString()+" to "+dst.ToString()
	End
	
	Method TransUnaryExpr$( expr:UnaryExpr )
		Local pri=ExprPri( expr )
		Local t_expr$=TransSubExpr( expr.expr,pri )
'		Return TransUnaryOp( expr.op )+t_expr
		If( expr.op = "not" )
			Return "(" + TransUnaryOp( expr.op )+t_expr + ")"
		Else
			Return TransUnaryOp( expr.op )+t_expr
		Endif
	End
	
	Method TransBinaryExpr$( expr:BinaryExpr )
		Local pri=ExprPri( expr )
		Local t_lhs$=TransSubExpr( expr.lhs,pri )
		Local t_rhs$=TransSubExpr( expr.rhs,pri-1 )
		' looks like BlitMax's order of precedence is a bit different with the bit shifting, so we will wrap the rhs in brackets...
		if expr.op = "shr" Or expr.op = "sar" Or expr.op = "shl"
			t_rhs = Bra(t_rhs)
		End
		
		Local t_expr$=t_lhs+TransBinaryOp( expr.op,t_rhs )+t_rhs
		If expr.op="/" And IntType( expr.exprType ) t_expr=Bra( Bra(t_expr)+"|0" )
		
'		Return t_expr
		If( expr.op="and" Or expr.op="or")
			Return "(" + t_expr + ")"
		Else
			Return t_expr
		Endif
	End
	
	Method TransIndexExpr$( expr:IndexExpr )
		Local t_expr:=TransSubExpr( expr.expr )
		If StringType( expr.expr.exprType ) 
			Local t_index:=expr.index.Trans()
			'Return t_expr+".charCodeAt("+t_index+")"
			'Return t_expr+".Find("+t_expr+","+t_index+")"
			Return t_expr+"["+t_index+"]"
'			Return "Int("+t_expr+"["+t_index+"])"
		Else If ENV_CONFIG="debug"
			Local t_index:=TransExprNS( expr.index )
			Return t_expr+"["+t_index+"]"
		Else
			Local t_index:=expr.index.Trans()
			Return t_expr+"["+t_index+"]"
		Endif
	End
#Rem
	Method TransSliceExpr$( expr:SliceExpr )
		Local t_expr$=TransSubExpr( expr.expr )
		Local t_args$="0"
		If Not expr.from And Not expr.term
			Return t_expr+"[..]"
		Endif
		If expr.from t_args=expr.from.Trans()
'		If expr.term t_args+=","+expr.term.Trans()
		t_args+=".."
		If expr.term t_args+="("+expr.term.Trans()+")"
'		Return t_expr+".slice("+t_args+")"
		If StringType( expr.exprType )
		
			Return "bb_std_lang.slice("+expr.exprType+","+expr.from+","+expr.term+")"
		Endif
		Return t_expr+"["+t_args+"]"		
		InternalErr("TransSliceExpr")
	End


	Method TransSliceExpr$( expr:SliceExpr )
		Local texpr$=expr.expr.Trans()
		Local from$=",0",term$
		If expr.from from=","+expr.from.Trans()
		If expr.term term=","+expr.term.Trans()
		If ArrayType( expr.exprType )
			Return "(("+TransType( expr.exprType )+")bb_std_lang.sliceArray"+Bra( texpr+from+term )+")"
		Else If StringType( expr.exprType )
			Return "bb_std_lang.slice("+texpr+from+term+")"
		Endif
		InternalErr("TransSliceExpr")
	End
#End
	Method TransSliceExpr$( expr:SliceExpr )
		If ArrayType( expr.exprType )
			Local t_expr$=TransSubExpr( expr.expr )
			Local t_args$="0"
			If Not expr.from And Not expr.term
				Return t_expr+"[..]"
			Endif
			If expr.from t_args=expr.from.Trans()
	'		If expr.term t_args+=","+expr.term.Trans()
			t_args+=".."
			If expr.term t_args+="("+expr.term.Trans()+")"
	'		Return t_expr+".slice("+t_args+")"
			Return t_expr+"["+t_args+"]"
		Else If StringType( expr.exprType )
			Local texpr$=expr.expr.Trans()
			Local from$=",0",term$
			If expr.from from=","+expr.from.Trans()
			If expr.term term=","+expr.term.Trans()
		
			Return "slice_string("+texpr+from+term+")"
		Endif
		InternalErr("TransSliceExpr")
	End
	
	Method TransArrayExpr$( expr:ArrayExpr )
		Local t$
		For Local elem:=Eachin expr.exprs
			If t t+=","
			t+=elem.Trans()
		Next
		Return "["+t+"]"
	End
	
	Method TransIntrinsicExpr$( decl:Decl,expr:Expr,args:Expr[] )
	
		Local texpr$,arg0$,arg1$,arg2$
		
		If expr texpr=TransSubExpr( expr )
		
		If args.Length>0 And args[0] arg0=args[0].Trans()
		If args.Length>1 And args[1] arg1=args[1].Trans()
		If args.Length>2 And args[2] arg2=args[2].Trans()
		
		Local id$=decl.munged[1..]
		
		Select id

		'global functions
		Case "print" Return "print("+arg0+")" ' done
		Case "error" Return "error("+arg0+")"
		Case "debuglog" Return "debugLog"+Bra( arg0 )
		Case "debugstop" Return "debugStop()"

		'string/array methods
		Case "length" Return texpr+".length" ' tested and works
		
		'array methods ' TODO!!!
		Case "resize"
			Local ty:=ArrayType( expr.exprType ).elemType
			If BoolType( ty ) Return "resize_int_array"+Bra( texpr+","+arg0 ) ' bools are ints in BlitzMax!
			If IntType( ty ) Return "resize_int_array"+Bra( texpr+","+arg0 ) ' done
			If FloatType( ty ) Return "resize_float_array"+Bra( texpr+","+arg0 ) ' done
			If StringType( ty ) Return "resize_string_array"+Bra( texpr+","+arg0 ) ' done
			If ArrayType( ty ) Return "resize_array_array_"+ArrayType( ty ).elemType+Bra( texpr+","+arg0 )
'			If ObjectType( ty ) Return "resize_object_array"+Bra( TransType(ty )+Bra (texpr)+","+arg0 )
			If ObjectType( ty ) Return texpr+"[.."+arg0+"]"
			InternalErr("TransIntrinsicExpr1")

		'string methods
		' Done all for BMax
		Case "compare" Return texpr+".Compare"+Bra( arg0 )
		Case "find" Return texpr+".Find"+Bra( arg0+","+arg1 )
		Case "findlast" Return texpr+".FindLast"+Bra( arg0 )
		Case "findlast2" Return texpr+".FindLast"+Bra( arg0+","+arg1 )
		Case "trim" Return texpr+".Trim()"
		Case "join" Return texpr+".Join"+Bra(arg0)
		Case "split" Return texpr+".Split"+Bra( arg0 )
		Case "replace" Return texpr+".Replace"+Bra(arg0+","+arg1)
		Case "tolower" Return texpr+".ToLower()"
		Case "toupper" Return texpr+".ToUpper()"
		Case "contains" Return texpr+".Contains"+Bra( arg0 )
		Case "startswith" Return texpr+".StartsWith"+Bra( arg0 )
		Case "endswith" Return texpr+".EndsWith"+Bra( arg0 )
		Case "tochars" Return texpr+".ToCString()"

		'string functions
'		Case "fromchar" Return "String.fromCharCode"+Bra( arg0 )
		Case "fromchar" Return "Chr" + Bra(arg0)
		Case "fromchars" Return "string_from_chars" + Bra(arg0)

		' ** TO-DO **
		' BlitzMax angle stuff isnt proper, need to minus 90 I think from the angle!
		
		'trig functions - degrees
		' Done all for BMax
		Case "sin","cos","tan" Return id+Bra(arg0)' "Math."+id+Bra( Bra( arg0 )+"*D2R" )
		Case "asin","acos","atan" Return id+Bra(arg0)' Bra( "Math."+id+Bra( arg0 )+"*R2D" )
		Case "atan2" Return id+Bra(arg0+","+arg1) 'Bra( "Math."+id+Bra( arg0+","+arg1 )+"*R2D" )
		
		'trig functions - radians
		' Done all for BMax
		Case "sinr" Return id[..-1]+Bra( Bra( arg0 +"*R2D") )
		Case "cosr" Return id[..-1]+Bra( Bra( arg0 +"*R2D") )
		Case "tanr" Return id[..-1]+Bra( Bra( arg0 +"*R2D") )
		Case "asinr" Return id[..-1]+Bra( arg0 )+"*D2R"
		Case "acosr" Return id[..-1]+Bra( arg0 )+"*D2R"
		Case "atanr" Return id[..-1]+Bra( arg0 )+"*D2R"
		Case "atan2r" Return id[..-1]+Bra(arg0+","+arg1)+"*D2R"

		'misc math functions
		' Done all for BMax
		Case "floor","ceil","log","exp" Return id+Bra( arg0 )
		Case "sqrt" Return "Sqr"+Bra(arg0)
		Case "pow" Return "(" + Bra(arg0) + "^" + Bra(arg1) + ")"

		End Select

		InternalErr("TransIntrinsicExpr2")
	End
	
	'***** Statements *****

	Method TransTryStmt$( stmt:TryStmt )
		Emit "Try"
		Local unr:=EmitBlock( stmt.block )
		For Local c:=Eachin stmt.catches
			MungDecl c.init
			Emit "Catch "+c.init.munged+":"+TransType( c.init.type )
			Local unr:=EmitBlock( c.block )
		Next
		Emit "EndTry"
	End
	
	Method TransAssignStmt$( stmt:AssignStmt )
	#rem
		If ENV_CONFIG="debug"
			Local ie:=IndexExpr( stmt.lhs )
			If ie
				Local t_rhs:=stmt.rhs.Trans()
				Local t_expr:=ie.expr.Trans()
				Local t_index:=TransExprNS( ie.index )
				Emit "dbg_array("+t_expr+","+t_index+")["+t_index+"]"+stmt.op+t_rhs
				Return
			Endif
		Endif
	#End
		Return Super.TransAssignStmt( stmt )
	End
	
	
	'***** Declarations *****
	
	Method EmitFuncDecl( decl:FuncDecl )
		BeginLocalScope
'		PushMungScope

		'Find decl we override
		Local odecl:=decl
		While odecl.overrides
			odecl=odecl.overrides
		Wend

		'Generate 'args' string and arg casts
		Local args$
		Local argCasts:=New StringStack
		For Local i=0 Until decl.argDecls.Length
			Local arg:=decl.argDecls[i]
			Local oarg:=odecl.argDecls[i]
			MungDecl arg
			If args args+=","
			args+=arg.munged+":"+TransType( oarg.type )
			If arg.type.EqualsType( oarg.type ) Continue
			Local t$=arg.munged
			arg.munged=""
			MungDecl arg
			'argCasts.Push "Local "+arg.munged+":"+TransType(arg.ty)+"="+t+" new "+TransType(arg.ty)+";"
			argCasts.Push "Local "+arg.munged+":"+TransType(arg.type)+"="+TransType(arg.type)+Bra(t)
		Next

'		Local t$=" "+decl.munged+":"+TransType( odecl.retType )+Bra( args )
		Local t$
		If VoidType( odecl.retType )
			t=" "+decl.munged+Bra( args )
		Else
			t=" "+decl.munged+":"+TransType( odecl.retType )+Bra( args )
		Endif
		Local funcType$ = "Function"
		Local cdecl:=decl.ClassScope()
		If cdecl And cdecl.IsInterface()
'			Emit funcType+" "+t+";"

			Local q$
			funcType = "Method"
			q+=funcType+" "

			If decl.IsAbstract()
				Emit q+t+" Abstract"
			Else
				Emit q+t+""
			End
			
			If decl.IsAbstract()
				If VoidType( decl.retType )
				'	Emit "return 0;" ' return 0 as Void = Int for BlitzMax ;)
				Else
				'	Emit "return "+TransValue( decl.retType,"" )+";"
				Endif
			Else
				For Local t$=Eachin argCasts
					Emit t
				Next
				EmitBlock decl
			Endif
			If decl.IsAbstract()
				indent=indent[..indent.Length-1]
			Else
				Emit "End"+funcType
			End

		Else
			Local q$'="internal "
			If cdecl
			'	q="public "
				If decl.IsStatic()
					q+=funcType+" "
				Else
					funcType = "Method"
					q+=funcType+" "
				Endif
			'	If decl.overrides q+="override "
			Else
				q+=funcType+" "
			Endif
			If decl.IsAbstract()
				Emit q+t+" Abstract"
			Else
				Emit q+t+""
			End
			
			If decl.IsAbstract()
				If VoidType( decl.retType )
				'	Emit "return 0;" ' return 0 as Void = Int for BlitzMax ;)
				Else
				'	Emit "return "+TransValue( decl.retType,"" )+";"
				Endif
			Else
				For Local t$=Eachin argCasts
					Emit t
				Next
				EmitBlock decl
			Endif
			If decl.IsAbstract()
				indent=indent[..indent.Length-1]
			Else
				Emit "End"+funcType
			End
			
		Endif

		EndLocalScope		
'		PopMungScope
	End
#rem	
	'returns unreachable status!
	Method EmitBlock( block:BlockDecl )
	
		PushEnv block
		
		Local func:=FuncDecl( block )
		
		If func 
			If func.IsAbstract() InternalErr("EmitBlock")
			If ENV_CONFIG<>"release" EmitEnter func.scope.ident+"."+func.ident
		Endif

		For Local stmt:Stmt=Eachin block.stmts
		
			_errInfo=stmt.errInfo
			
			If unreachable	' And ENV_LANG<>"as"
				'If stmt.errInfo Print "Unreachable:"+stmt.errInfo
				Exit
			Endif

			If ENV_CONFIG<>"release"
				Local rs:=ReturnStmt( stmt )
				If rs
					If rs.expr
						EmitSetErr stmt.errInfo
						Local t_expr:=TransExprNS( rs.expr )
						EmitLeave
						Emit "return "+t_expr+";"
					Else
						EmitLeave
						Emit "return;"
					Endif
					unreachable=True
					Continue
				Endif
				EmitSetErr stmt.errInfo
			Endif
			
			Local t$=stmt.Trans()
			If t Emit t+";"
			
		Next
		
		Local r=unreachable
		unreachable=False
		
		If func And Not r

			If ENV_CONFIG<>"release" EmitLeave
			
			If Not VoidType( func.retType )
				If func.IsCtor()
					Emit "return self;"
				Else
					If func.ModuleScope().IsStrict()
						_errInfo=func.errInfo
						Err "Missing return statement."
					Endif
					Emit "return "+TransValue( func.retType,"" )+";"
				Endif
			Endif

		Endif
		
		PopEnv
		
		Return r
	End
#end
	'returns unreachable status!
	'
	Method EmitBlock( block:BlockDecl,realBlock?=True )
	
		PushEnv block
		
		Local func:=FuncDecl( block )
		
		If func
			emitDebugInfo=ENV_CONFIG<>"release"
			If func.attrs & DECL_NODEBUG emitDebugInfo=False
			If emitDebugInfo EmitEnter func
		Else
			If emitDebugInfo And realBlock EmitEnterBlock
		Endif

		For Local stmt:Stmt=Eachin block.stmts
		
			_errInfo=stmt.errInfo
			
			If unreachable Exit

			If emitDebugInfo
				Local rs:=ReturnStmt( stmt )
				If rs
					If rs.expr
						'
						If stmt.errInfo EmitSetErr stmt.errInfo
						'
						Local t_expr:=TransExprNS( rs.expr )
						EmitLeave
						Emit "Return "+t_expr+";"
					Else
						EmitLeave
						Emit "Return;"
					Endif
					unreachable=True
					Continue
				Endif
				'
				If stmt.errInfo EmitSetErr stmt.errInfo
				'
			Endif
			
			Local t$=stmt.Trans()
			If t Emit t
			
		Next
		
		_errInfo=""
		
		Local unr=unreachable
		unreachable=False
		
		If unr

			'Actionscript's reachability analysis is...weird.
			If func And ENV_LANG="as" And Not VoidType( func.retType )
				If block.stmts.IsEmpty() Or Not ReturnStmt( block.stmts.Last() )
					Emit "Return "+TransValue( func.retType,"" )
				Endif
			Endif
		
		Else If func
		
			If emitDebugInfo EmitLeave
			
			If Not VoidType( func.retType )
				If func.IsCtor()
					Emit "return Self"
				Else
					If func.ModuleScope().IsStrict()
						_errInfo=func.errInfo
						Err "Missing return statement."
					Endif
					Emit "Return "+TransValue( func.retType,"" )
				Endif
			Endif
		Else

			If emitDebugInfo And realBlock EmitLeaveBlock

		Endif

		PopEnv
		
		Return unr
	End

	Method Enquote$( str$ )
		str = str.Replace("~~", "~~~~")
		str = str.Replace("~q", "~~q")
		str = str.Replace("~n", "~~n")
		str = str.Replace("~r", "~~r")
		str = str.Replace("~t", "~~t")
		
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

	Method Emit( t$ )
		If Not t Return
		
		't=t.Replace( "\n","~~n" )
		
		If t.StartsWith( "EndIf" ) Or t.StartsWith( "EndFunction" ) Or t.StartsWith( "EndMethod" ) Or t.StartsWith( "EndType" ) Or t.StartsWith("Next") Or t.StartsWith("Else") Or t.StartsWith( "Wend" )
			indent=indent[..indent.Length-1]
		Endif
		lines.Push indent+t
		'code+=indent+t+"~n"
		If t.EndsWith( "Then" ) Or t.StartsWith( "Function" ) Or t.StartsWith( "Method" ) Or t.StartsWith( "Type" ) Or t.StartsWith("For") Or t.StartsWith("Else") Or t.StartsWith("While")
			indent+="~t"
		Endif
	End
	
	Method TransUnaryOp$( op$ )
'		Print "TransUnaryOp op="+op
		Select op
		Case "+" Return "+"
		Case "-" Return "-"
		Case "~~" Return op
		Case "not" Return op+" "
		End Select
		InternalErr("TransUnaryOp")
	End
	
	Method TransAssignOp$( op$ )
'		Print "TransAssignOp op="+op
		Select op
			Case "mod=" Return " :Mod "
			Case "shl=" Return " :shl "
			Case "shr=" Return " :sar " ' Monkey's Shr is BlitzMax's Sar
			Case "+=" Return " :+"
			Case "-=" Return " :-"
			Case "*=" Return " :*"
			Case "/=" Return " :/"
			Case "|=" Return " :|"
			Case "&=" Return " :&"
		End
		Return op
	End
	
	Method TransBinaryOp$( op$,rhs$ )
	#rem
		Select op
		Case "+","-"
			If rhs.StartsWith( op ) Return op+" "
			Return op
		Case "*","/" Return op
		Case "shl" Return op
		Case "shr" Return "sar" ' Monkey's Shr is BlitzMax's Sar
		Case "mod" Return op
		Case "and" Return op
		Case "or" Return op
		Case "=" Return op
		Case "<>" Return op
		Case "<","<=",">",">=" Return op
		Case "&","|" Return op
		Case "~~" Return "^"
		End Select
	#end
		Select op
			Case 
				"shr" Return " sar " ' Monkey's Shr is BlitzMax's Sar
			Default
				Return " " + op + " "
		End Select
		
		InternalErr("TransBinaryOp")
	End
	
	Method TransIfStmt$( stmt:IfStmt )
		
		If ConstExpr( stmt.expr )
			If ConstExpr( stmt.expr ).value
				If EmitBlock( stmt.thenBlock ) unreachable=True
			Else If Not stmt.elseBlock.stmts.IsEmpty()
				If EmitBlock( stmt.elseBlock ) unreachable=True
			Endif
		Else If Not stmt.elseBlock.stmts.IsEmpty()
			Emit "If"+Bra( stmt.expr.Trans() )+" Then"
			Local unr=EmitBlock( stmt.thenBlock )
			Emit "Else"
			Local unr2=EmitBlock( stmt.elseBlock )
			Emit "EndIf"
			If unr And unr2 unreachable=True
		Else
			Emit "If"+Bra( stmt.expr.Trans() )+" Then"
			Local unr=EmitBlock( stmt.thenBlock )
			Emit "EndIf"
		Endif
	End
	
	Method EmitClassDecl( classDecl:ClassDecl )

		If KLUDGE_INTERFACES
			If classDecl.IsInterface() Return
		Endif
	
'		If classDecl.IsTemplateInst()
'			InternalErr
'		Endif
	
		Local classid$=classDecl.munged
		Local superid$=classDecl.superClass.munged

'		Print "superid = "+superid + " " + classid
		
		If classDecl.IsInterface() 

			Local bases$

			If Not KLUDGE_INTERFACES
				For Local iface:=Eachin classDecl.implments
					If bases bases+="," Else bases=" extends "
					bases+=iface.munged
				Next
			Endif

			Local ab$=""
			If classDecl.IsAbstract()
				ab="Abstract"
			End

			If superid<>"Object"
				Emit "Type "+classid+" extends "+superid+bases + " " + ab
			Else
				Emit "Type "+classid + " " + ab
			Endif
'			Emit "interface "+classid+bases+"{"
			
			For Local decl:=Eachin classDecl.Semanted
				Local fdecl:=FuncDecl( decl )
				If Not fdecl Continue
				EmitFuncDecl fdecl
			Next
			Emit "EndType"
'			Emit "}"
			Return
		Endif

		Local bases$

		If Not KLUDGE_INTERFACES
			For Local iface:=Eachin classDecl.implments
  '			If bases bases+="," Else bases=" implements "
				If bases bases+="," Else bases=" extends "
				bases+=iface.munged
			Next
		Endif

		Local ab$=""
		If classDecl.IsAbstract()
			ab="Abstract"
		End
		
		If superid<>"Object"
			Emit "Type "+classid+" extends "+superid+bases + " " + ab
		Elseif bases<>""
			Emit "Type "+classid+bases + " " + ab
		Else
			Emit "Type "+classid + " " + ab
		Endif
		
		'members...
		For Local decl:=Eachin classDecl.Semanted
			Local tdecl:=FieldDecl( decl )
			If tdecl
				Emit "Field "+TransValDecl( tdecl )+"="+tdecl.init.Trans()+";"
				Continue
			Endif
			
			Local gdecl:=GlobalDecl( decl )
			If gdecl
				Emit "Global "+TransValDecl( gdecl )+";"
				Continue
			Endif
			
			Local fdecl:=FuncDecl( decl )
			If fdecl
				EmitFuncDecl fdecl
				Continue
			Endif
		Next
		
		Emit "EndType"
	End
	
	Method TransWhileStmt$( stmt:WhileStmt )
		Local nbroken=broken
		
		Emit "While"+Bra( stmt.expr.Trans() )+""
		Local unr=EmitBlock( stmt.block )
		Emit "Wend"
		
		If broken=nbroken And ConstExpr( stmt.expr ) And ConstExpr( stmt.expr ).value unreachable=True
		broken=nbroken
	End
	
	Method TransRepeatStmt$( stmt:RepeatStmt )
		Local nbroken=broken

		Emit "Repeat"
		Local unr=EmitBlock( stmt.block )
		Emit "Until ("+Bra( stmt.expr.Trans() )+");"

		If broken=nbroken And ConstExpr( stmt.expr ) And Not ConstExpr( stmt.expr ).value unreachable=True
		broken=nbroken
	End
	
	Method TransForStmt$( stmt:ForStmt )
		Local nbroken=broken

		Local init$=stmt.init.Trans()
		Local expr$=stmt.expr.Trans()
		Local incr$=stmt.incr.Trans()

		Local splitExpr:= expr.Split(" ")
		Local splitIncr:= incr.Split(" ")
		Local bmaxExpr$ = splitExpr[1]
		Local bmaxIncr$ = splitIncr[2]

		If bmaxExpr="<=" Or bmaxExpr=">="
			bmaxExpr = "To"
		Else If bmaxExpr="<" Or bmaxExpr=">"
			bmaxExpr = "Until"
		End

'		If( splitExpr.Length > 3 )
			Local out$="For "+init+" "+bmaxExpr +" "
			Local sc:Int=2
			Local first:Bool = True
			While sc < splitExpr.Length
				If first
					first=False
				Else
					out+=" "
				Endif
				out+=splitExpr[sc]
				sc+=1
			Wend
			out+=" Step "+ bmaxIncr
			Emit out
'		Else
'			Emit "For "+init+" "+bmaxExpr +" "+splitExpr[2]+ " Step "+ bmaxIncr
'		Endif
		Local unr=EmitBlock( stmt.block )
		Emit "Next"

		If broken=nbroken And ConstExpr( stmt.expr ) And ConstExpr( stmt.expr ).value unreachable=True
		broken=nbroken
	End
	
	Method TransBreakStmt$( stmt:BreakStmt )
		unreachable=True
		broken+=1
		Return "Exit"
	End

	Method TransApp$( app:AppDecl )

		If KLUDGE_INTERFACES	
			KludgeInterfaces app
		Endif

'		app.mainFunc.munged="bbMain"
		app.mainFunc.munged="bbMain2"
		
		For Local decl:=Eachin app.imported.Values()
			MungDecl decl
		Next
		
		For Local decl:=Eachin app.Semanted

			MungDecl decl

			Local cdecl:=ClassDecl( decl )
			If Not cdecl Continue

			BeginLocalScope			
'			PushMungScope

			For Local decl:=Eachin cdecl.Semanted
				If FuncDecl( decl ) And FuncDecl( decl ).IsCtor()
					decl.ident=cdecl.ident+"_"+decl.ident
				Endif
				MungDecl decl
			Next
			
			EndLocalScope
'			PopMungScope
		Next
	
		'decls
		'
		For Local decl:=Eachin app.Semanted

			Local gdecl:=GlobalDecl( decl )
			If gdecl
				Emit "Global "+TransValDecl( gdecl )+";"
				Continue
			Endif
			
			Local fdecl:=FuncDecl( decl )
			If fdecl
				EmitFuncDecl fdecl
				Continue
			Endif
			
			Local cdecl:=ClassDecl( decl )
			If cdecl
				EmitClassDecl cdecl
				Continue
			Endif
		Next
		
		Emit "Function bbInit()"
		For Local decl:=Eachin app.semantedGlobals
			Emit TransGlobal( decl )+"="+decl.init.Trans()+";"
		Next
		Emit "EndFunction"

		Emit "Function bbMain:Int()"
		Emit "~tLocal r:Int=bbMain2();"
		Local found:Bool = False
		For Local s:String = Eachin lines
			If s.Contains( "bb_app_device" )
				found = True
				Exit
			Endif
		Next
		If found
			Emit "~tbb_app_device.Setup();"
		Endif
		Emit "~treturn r;"
		Emit "EndFunction"
		
		Return JoinLines()
	End

	Method MungDecl( decl:Decl )

		If decl.munged Return

		Local fdecl:FuncDecl=FuncDecl( decl )
		If fdecl And fdecl.IsMethod() Return MungMethodDecl( fdecl )
		
		Local mscope$,cscope$
		If decl.ClassScope() cscope=decl.ClassScope().munged
		If decl.ModuleScope() mscope=decl.ModuleScope().munged
		
		Local id:=decl.ident,munged$,scope$
		
		If LocalDecl( decl )
			scope="$"
			munged="t_"+id
		Else If FieldDecl( decl )
			scope=cscope
			munged="f_"+id
		Else If GlobalDecl( decl ) Or FuncDecl( decl )
			If cscope And ENV_LANG<>"js"
				scope=cscope
				munged="g_"+id
			Else If cscope
				munged=cscope+"_"+id
			Else
				munged=mscope+"_"+id
			Endif
		Else If ClassDecl( decl )
			munged=mscope+"_"+id
		Else If ModuleDecl( decl )
			munged="bb_"+id
		Else
			Print "OOPS1"
			InternalErr("MungDecl")
		Endif

		''' Modify the "munged" variable:
		''' change uppercase characters to _1
		
		Local newmunged:String
		For Local i:Int = 0 Until munged.Length
			Local c:Int = munged[i]
			If c = "_1" Then
				newmunged += "_1" + "_1"
			ElseIf c >= 65 And c <= 90 Then
				newmunged += "_1" + String.FromChar(c)
			Else
				newmunged += String.FromChar(c)
			End
		Next
		munged = newmunged

		Local set:=mungedScopes.Get( scope )
		If set
			If set.Contains( munged )
				Local id=1
				Repeat
					id+=1
					Local t$=munged+String(id)
					If set.Contains(t) Continue
					munged=t
					Exit
				Forever
			Endif
		Else
			If scope="$"
				Print "OOPS2"
				InternalErr("MungDecl2")
			Endif
			set=New StringSet
			mungedScopes.Set scope,set
		Endif
		set.Insert munged
		decl.munged=munged
	End
	
End