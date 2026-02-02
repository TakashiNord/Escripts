#-------------------------------------------------------------------------------
 #
 # xml2gui, version 1.0
 #
 # PURPOSE:
 #
 #     Creates a GUI based on an XML description.
 #
 #-------------------------------------------------------------------------------
 
 namespace eval ::xml2gui {
     package require Tcl 8.3
     package require Tk  8.3
     package require tdom 0.7.7
 }
 
 
 #-------------------------------------------------------------------------------
 # Create the $child of a $parent
 #
 proc ::xml2gui::Create {child parent} {
     foreach node [list $child $parent] {
         set type($node) [$node nodeName] 
         set name($node) [$node getAttribute NAME ""]
     }
 
     # Dispatch based on the name (type) of the child node
     # row, col, configure, tcl, and null, receive special treatment.
     # All other node names are presumed to be the name of a type of 
     # Tk widget (or megawidget).
     switch -exact -- $type($child) {
         row       { GridConfigure rowconfigure $child $parent }
         col       { GridConfigure columnconfigure $child $parent }
         configure { Configure $child $parent }
         tcl       { TclCode $child $parent }
         null      { /dev/null }
         default   { CreateWidget $child $parent }
     }
 
     # For new <row />, we increment rowcount & reset column to 0
     if {$type($child) == "row"} {
         $parent setAttribute ROW [expr {[$parent getAttribute ROW] + 1}]
         $parent setAttribute COL 0
     } elseif {[lsearch -exact {col configure tcl} $type($child)] == -1} {
         # For any widget (or null placeholder), increment column
         $parent setAttribute COL [expr {[$parent getAttribute COL] + 
                                         [$child getAttribute COLSPAN 1]}]
     }
 
 
     # If a widget has children widgets, then it must be a container of
     # some sort (i.e., Frame, BLT tabset, BWidget ScrolledWindow, etc.)
     # so we set row = 0, col = 0.  On the other hand, it might be a regular
     # widget with a <tcl>...</tcl> child, in which case we'll never use
     # the row & col settings, but it doesn't hurt to set them.
     if {[$child hasChildNodes] && $type($child) != "tcl"} {
         $child setAttribute ROW 0
         $child setAttribute COL 0
 
         # Create each descendant widget recursively,
         # taking care to ignore COMMENT_NODEs, etc.
         foreach grandchild [$child childNodes] {
             if {[$grandchild nodeType] == "ELEMENT_NODE"} {
                 Create $grandchild $child
             }
         }
     }
 }
 
 
 #-------------------------------------------------------------------------------
 # Special handling for <row /> & <col /> 
 #
 proc ::xml2gui::GridConfigure {mode child parent} {
     if {$mode == "rowconfigure"} {
         set pos [$parent getAttribute ROW]
     } elseif {$mode == "columnconfigure"} {
         # COL contains the "next" column number, so we subtract one to
         # get the "current" column number
         set pos [expr {[$parent getAttribute COL] - 1}]
     }
 
     grid $mode [$parent getAttribute PATH] $pos \
         -weight [$child getAttribute weight 0]
 }
 
 
 #-------------------------------------------------------------------------------
 # /dev/null is a no-op for <null /> (side effect is that the current COL 
 # number is incremented)
 #
 proc ::xml2gui::/dev/null args {}
 
 
 #-------------------------------------------------------------------------------
 # BuildCommand
 #
 proc ::xml2gui::BuildCommand {child path {command {}}} {
     foreach attribute [$child attributes] {
         # All caps attributes are reserved for xml2gui's use 
         # (we don't know of any megawidget that uses an all-caps 
         # configuration -OPTION)
         if {[string equal $attribute [string toupper $attribute]]} then continue
 
         # incrementally build up our command, substituting 
         # @PARENT@ with the widget name of our parent, and
         # @SELFNODE@ with the tDOM node of the widget being created
         # (the latter is probably only useful in conjunction with the
         # tdg package)
         lappend command -$attribute \
             [string map [list @PARENT@ $path @SELFNODE@ $child] \
                 [$child getAttribute $attribute]]
     }
 
     return $command
 }
 
 
 #-------------------------------------------------------------------------------
 # Configure the $child of a $parent for some <widget />
 #
 proc ::xml2gui::Configure {child parent} {
     set path [$parent getAttribute PATH]
     set widget [string map [list @PARENT@ $path] [$child getAttribute NAME]]
 
     set command [BuildCommand $child $path]
     if {[llength $command]} {
         eval [list $widget] configure $command
     }
 }
 
 
 #-------------------------------------------------------------------------------
 # Special handling for <tcl>...</tcl>
 #
 proc ::xml2gui::TclCode {child parent} {
     # If <tcl> has no child text() node, then we have no code to execute
     if {[set node [$child selectNodes text()]] == ""} then return
 
     set path [$parent getAttribute PATH]
     eval [string map [list @PARENT@ $path @SELFNODE@ $child] [$node data]]
 }
 
 
 #-------------------------------------------------------------------------------
 # Create a <widget />
 #
 proc ::xml2gui::CreateWidget {child parent} {
     upvar 1 type type
     upvar 1 name name
 
     # Make sure we have the right package loaded to be able to create 
     # the requested type of widget
     #
     # (Other megawidgets can be used assuming they've been properly 
     # [package require'd] previously ...)
     switch -exact -- $type($child) {
         table           { package require Tktable }
         tabset          -
         graph           -
         stripchart      -
         barchart        -
         chart           { package require BLT }
         Dialog          -
         MainFrame       -
         LabelFrame      -
         TitleFrame      -
         ScrolledWindow  -
         PagesManager    -
         ScrollableFrame { package require BWidget }
         default         { package require Tk }
     }
 
     # Find out the name of the parent widget
     set path [$parent getAttribute PATH]
     set widget $path
 
 
     # Unless this widget is a BLT <tab>
     if {$type($child) != "tab"} {
         # If the parent is not the "." root window, append a . before the
         # child's name to create the path of the new widget
         if {[string index $widget end] != "."} {
             append widget .
         }
         append widget $name($child)
     } 
 
     # default initially to PATH == $widget
     $child setAttribute PATH $widget
 
     # We don't need to create (and can't!) the "." toplevel, for instance
     if {$type($child) != "tab" && [info commands $widget] != ""} then return
 
     # Command to create the widget
     if {$type($parent) != "canvas"} {
         switch -exact -- $type($child) {
             tabset    { set command [list ::blt::tabset $widget]   }
             tab       { set command [list $path insert end $name($child)]  }
             graph     { set command [list ::blt::graph $widget]    }
             barchart  -
             chart     { set command [list ::blt::barchart $widget] }
             default   { set command [list $type($child) $widget]   }
         }
     } else {
         set command [list $path create $type($child) \
             [$child getAttribute COORDS]]
     }
 
     set command [BuildCommand $child $path $command]
 
     # Create the widget.  No error catching.  If the widget syntax fails,
     # so be it.
     eval $command
 
     # Some megawidgets have a different frame for future child widgets
     switch -exact -- $type($child) {
         Dialog          -
         MainFrame       -
         LabelFrame      -
         TitleFrame      -
         ScrolledWindow  -
         ScrollableFrame { $child setAttribute PATH [$widget getframe] }
     }
 
     if {$type($parent) == "tab"} {
         # The BLT tabset manages the geometry of children of <tab> 
         $path tab configure $name($parent) -window $widget \
             -fill   [$child getAttribute FILL both] \
             -anchor [$child getAttribute ANCHOR center]
     } elseif {$type($parent) == "canvas"} {
         # Canvas takes care of it's own internal geometry management
     } elseif {$type($child) != "tab" && $type($child) != "toplevel"} {
         # Non <tab>'s & non-<toplevel>'s use the grid geometry manager
         grid $widget -row     [$parent getAttribute ROW] \
                      -column  [$parent getAttribute COL] \
                      -ipadx   [$child getAttribute IPADX 0] \
                      -ipady   [$child getAttribute IPADY 0] \
                      -padx    [$child getAttribute PADX 0] \
                      -pady    [$child getAttribute PADY 0] \
                      -sticky  [$child  getAttribute STICKY nsew] \
                      -rowspan [$child getAttribute ROWSPAN 1] \
                      -columnspan [$child getAttribute COLSPAN 1] 
     }
 
 
     # If requested, save the name of this newly created widget in a 
     # global (or namespace'd) variable
     if {[$child hasAttribute WIDGETVAR]} {
         set ::[$child getAttribute WIDGETVAR] $widget
     }
 
     # If requested, save the name of this newly created widget as an
     # attribute of a node in a tDOM DOM tree
     if {[$child hasAttribute WIDGETNODE] && 
         [$child hasAttribute WIDGETATTR]} {
         [$child getAttribute WIDGETNODE] setAttribute \
             [$child getAttribute WIDGETATTR] $widget
     }
 
     # Add additional bindtags.  A + (for add) must come at either the beginning
     # or end of the additional bindtag(s).  If at the beginning then the
     # bindtags are added before any existing ones; otherwise, bindtags are
     # added after any existing ones.
     if {[$child hasAttribute BINDTAGS]} {
         set tags [$child getAttribute BINDTAGS]
         set pos [lsearch -exact $tags +]
         if {$pos != -1} {
             set tags [lreplace $tags $pos $pos]
             if {$pos} {
                 bindtags $widget [concat [bindtags $widget] $tags]
             } else {
                 bindtags $widget [concat $tags [bindtags $widget]]
             }
         }
     }
 }
 
 
 #-------------------------------------------------------------------------------
 # create -- Create a GUI from an xml description
 # This is this packages sole public method.
 #
 proc ::xml2gui::create xml {
     set doc  [dom parse $xml]
     set root [$doc documentElement]
     set parent [$root selectNodes ..]
 
     $parent setAttribute PATH ""
     $parent setAttribute ROW 0
     $parent setAttribute COL 0
 
     $root setAttribute ROW 0
     $root setAttribute COL 0
 
     Create $root $parent
     $doc delete
 }
 
 package provide xml2gui 1.0
 
 
 
 set xml {
     <toplevel> 
         <tabset NAME="nb" STICKY="nsew" tearoff="0" 
             highlightthickness="0" WIDGETVAR="widgets(notebook)">
             <tab NAME="Cookbook" command="set ::window cookbook"> 
                 <frame NAME="editor" WIDGETVAR="widgets(cookbook)">
                     <frame NAME="static" STICKY="n">
                         <labelframe NAME="lf" WIDGETVAR="widgets(lf)" STICKY="n" 
                             text="Table of Contents"> 

                             <listbox NAME="toc" WIDGETVAR="widgets(toc)" 
                                 height="10" width="30" selectmode="single" 
                                 font="Arial 9" />

                         </labelframe>
                         <row />
                         <frame NAME="vspacer" height="3" />
                         <row />
                         <labelframe NAME="hlf" text="Brain-dead hints" STICKY="ew">
                             <text NAME="hints" WIDGETVAR="widgets(hints)" height="8"
                                 width="20" font="Arial 10 italic" relief="groove" />
                             <col weight="1" />
                             <row weight="1" />
                         </labelframe>
                     </frame>

                     <frame NAME="hspacer" width="10" STICKY="ns" />

                     <tabset NAME="pages" WIDGETVAR="widgets(pages)" STICKY="nsew"
                         samewidth="0" tearoff="0" highlightthickness="1">
                         <tab NAME="Title Page" command="#::cookbook::GUI::select 0"> 
                             <frame NAME="page" WIDGETVAR="widgets(tp)" 
                                 ANCHOR="nw" />
                         </tab>
                         <tab NAME="#1" command="##::cookbook::GUI::select 1">
                             <frame NAME="rcp1" WIDGETVAR="widgets(r1)" 
                                 ANCHOR="nw" />
                         </tab>
                         <tab NAME="#2" command="#::cookbook::GUI::select 2">
                             <frame NAME="rcp2" WIDGETVAR="widgets(r2)" 
                                 ANCHOR="nw" />
                         </tab>
                         <tab NAME="#3" command="#::cookbook::GUI::select 3">
                             <frame NAME="rcp3" WIDGETVAR="widgets(r3)" 
                                 ANCHOR="nw" />
                         </tab>
                         <tab NAME="#4" command="#::cookbook::GUI::select 4">
                             <frame NAME="rcp4" WIDGETVAR="widgets(r4)" 
                                 ANCHOR="nw" />
                         </tab>
                         <tab NAME="#5" command="#::cookbook::GUI::select 5">
                             <frame NAME="rcp5" WIDGETVAR="widgets(r5)" 
                                 ANCHOR="nw" />
                         </tab>
                         <tab NAME="#6" command="#::cookbook::GUI::select 6">
                             <frame NAME="rcp6" WIDGETVAR="widgets(r6)" 
                                 ANCHOR="nw" />
                         </tab>
                         <tab NAME="#7" command="#::cookbook::GUI::select 7">
                             <frame NAME="rcp7" WIDGETVAR="widgets(r7)" 
                                 ANCHOR="nw" />
                         </tab>
                         <tab NAME="#8" command="#::cookbook::GUI::select 8">
                             <frame NAME="rcp8" WIDGETVAR="widgets(r8)" 
                                 ANCHOR="nw" />
                         </tab>
                         <tab NAME="#9" command="#::cookbook::GUI::select 9">
                             <frame NAME="rcp9" WIDGETVAR="widgets(r9)" 
                                 ANCHOR="nw" />
                         </tab>
                     </tabset>
                     <col weight="1" />
                     <row weight="1" />
                 </frame>
             </tab>
             <tab NAME="Spreadsheet" command="set ::window spreadsheet">
                 <frame NAME="spreadsheet" WIDGETVAR="widgets(spreadsheet)">
                     <table NAME="table" variable="S" padx="1" pady="1"
                         xscrollcommand="@PARENT@.xscroll set" 
                         yscrollcommand="@PARENT@.yscroll set" />
                     <col weight="1" />
                     <scrollbar NAME="xscroll" orient="vertical" STICKY="ns" 
                         command="@PARENT@.table yview" />
                     <row weight="1" />
                     <scrollbar NAME="yscroll" orient="horizontal" STICKY="ew" 
                         command="@PARENT@.table xview" />
                 </frame>
             </tab>
             <tab NAME="Line Graph" command="set ::window line">
                 <frame NAME="linegraph" WIDGETVAR="widgets(graph)">
                     <graph NAME="graph" />
                     <col weight="1" />
                     <scrollbar NAME="xscroll" orient="vertical" STICKY="ns" 
                         command="@PARENT@.graph axis view y" />
                     <row weight="1" />
                     <scrollbar NAME="yscroll" orient="horizontal" STICKY="ew" 
                         command="@PARENT@.graph axis view x" />
                 </frame>
             </tab>
             <tab NAME="Bar Chart" command="set ::window bar">
                 <frame NAME="barchart" WIDGETVAR="widgets(barchart)">
                     <chart NAME="barchart" />
                     <col weight="1" />
                     <scrollbar NAME="xscroll" orient="vertical" STICKY="ns" 
                         command="@PARENT@.barchart axis view y" />
                     <row weight="1" />
                     <scrollbar NAME="yscroll" orient="horizontal" STICKY="ew" 
                         command="@PARENT@.barchart axis view x" />
                 </frame>
             </tab>
         </tabset>
         <col weight="1" />
         <row weight="1" />
         <label NAME="status" relief="sunken" WIDGETVAR="status" STICKY="ew" />
     </toplevel>
 }

 xml2gui::create $xml
 