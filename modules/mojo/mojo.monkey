
' Module mojo.mojo
'
' Copyright 2011 Mark Sibly, all rights reserved.
' No warranty implied; use at your own risk.

#If TARGET<>"html5" And TARGET<>"flash" And TARGET<>"glfw" And TARGET<>"xna" And TARGET<>"ios" And TARGET<>"android" And TARGET<>"pss" And TARGET<>"psm" And TARGET<>"win8" And TARGET<>"bmax"
#Error "The mojo module is not available on the ${TARGET} target"
#End

Import app
Import audio
Import graphics
Import input
Import asyncloaders
