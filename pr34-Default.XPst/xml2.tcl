 package require tdom
 
 proc recurseInsert {w node parent} {
    set name [$node nodeName]
    set done 0
    if {$name eq "#text"} {
       # || $name eq "#cdata"
        set text [string map {\n " "} [$node nodeValue]]
    } else {
        set text <$name
        foreach att [getAttributes $node] {
            catch {append text " $att=\"[$node getAttribute $att]\""}
        }
        append text >
        set children [$node childNodes]
        if {[llength $children]==1 && [$children nodeName] eq "#text"} {
            #append text [$children nodeValue] </$name>
            append text [$children nodeType] </$name>
            #append text [$children data] </$name>
            set done 1
        }
    }
    $w insert $parent end -id $node -text $text
    if {$parent eq {}} {$w item $node -open 1}
    if !$done {
        foreach child [$node childNodes] {
            recurseInsert $w $child $node
        }
    }
 }
 proc getAttributes node {
    if {![catch {$node attributes} res]} {set res}
 }
 
 #set            fp [open "C:\\rsdu\\Default.XPst"]
 # fconfigure    $fp -encoding utf-8
 #set xml [read $fp]
 #close         $fp
 
 
  set fd [tDOM::xmlOpenFile "C:\\rsdu\\Default.XPst"]
 
 set doc [dom parse -channel $fd ]
 close $fd
 $doc documentElement root
 

 ttk::treeview .t -yscrollcommand ".y set" -xscrollcommand ".x set"
 scrollbar .x -ori hori -command ".t xview"
 scrollbar .y -ori vert -command ".t yview"
 grid .t .y  -sticky news
 grid .x     -sticky news
 grid rowconfig    . 0 -weight 1
 grid columnconfig . 0 -weight 1
 
 after 5 {recurseInsert .t $root {}}