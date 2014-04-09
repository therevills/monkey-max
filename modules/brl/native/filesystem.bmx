' ***** Start filesystem.bmx ******
Type BBFileSystem

	Function FixPath:String( path:String )
        Return BBGame.Game().PathToFilePath( path )
    End Function

	Function FileType:Int( path:String )
        Return FileType( path )
    End Function

	Function FileSize:Int( path:String )
        Return FileSize( path )
    End Function

	Function FileTime:Int( path:String )
        Return FileTime( path )
    End Function

	Function CreateFile:Int( path:String )
        Return CreateFile( path )
    End Function

	Function DeleteFile:Int( path:String )
        Return DeleteFile( path )
    End Function

	Function CopyFile:Int( src:String,dst:String )
        Return CopyFile( src, dst )
    End Function

	Function CreateDir:Int( path:String )
        Return CreateDir( path )
    End Function

	Function DeleteDir:Int( path:String )
        Return DeleteDir( path )
    End Function

	Function LoadDir:String[]( path:String )
        Return LoadDir( path )
    End Function
End Type
' ***** End filesystem.bmx ******
