package require BWidget
 package require tdom
 
 proc insertNode {w parent node} {
     if {[$node nodeType] != "ELEMENT_NODE"} {
         # text, cdata, comment and PI nodes
         set text [string map {\n " "} [$node nodeValue]]
         set drawcross "auto"
     } else {
         set name "[$node nodeName]"
         set text "<$name"
         foreach att [getAttributes $node] {
             catch {append text " $att=\"[$node getAttribute $att]\""}
         }
         append text >
         if {![$node hasChildNodes]} {
             set drawcross "auto"
         } else {
             set children [$node childNodes]
             if {[llength $children]==1 && [$children nodeName]=="#text"} {
                 append text [string map {\n " "} [$children nodeValue]] </$name>
                 set drawcross "auto"
             } else {
                 set drawcross "allways"
             }
         }
     }
     $w insert end $parent $node -text $text -drawcross $drawcross
 }    
 
 proc getAttributes node {
     if {![catch {$node attributes} res]} {set res}
 }
 
 proc openClose {w node} {
     if {[$w itemcget $node -drawcross] == "allways"} {
         foreach child [$node childNodes] {
             insertNode $w $node $child
         }
         if {[$w parent $node] == "root"} {
             $w itemconfigure $node -open 1 ;# RS: added to auto-open
         }
         $w itemconfigure $node -drawcross "auto"
     }
 }    
 
 set fd [tDOM::xmlOpenFile "C:\\rsdu\\Default.XPst"]
 
 set doc [dom parse -channel $fd]
 close $fd
 $doc documentElement root
 
 Tree .t -yscrollcommand ".y set" -xscrollcommand ".x set" -padx 0 \
         -opencmd "openClose .t"
 
 scrollbar .x -ori hori -command ".t xview"
 scrollbar .y -ori vert -command ".t yview"
 grid .t .y  -sticky news
 grid .x     -sticky news
 grid rowconfig    . 0 -weight 1
 grid columnconfig . 0 -weight 1
 
 insertNode .t root $root
 # Show the childs of the root right after startup
 openClose .t $root