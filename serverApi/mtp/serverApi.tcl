# interface generated by SpecTcl version 1.1 from D:/serverApi.ui
#   root     is the parent window for this user interface

proc serverApi_ui {root args} {

	# this treats "." as a special case

	if {$root == "."} {
	    set base ""
	} else {
	    set base $root
	}
    
	label $base.label#1 \
		-text {SCADA API ip:port=}

	entry $base.entry_server_host \
		-textvariable server_host

	label $base.label#2 \
		-text user=

	entry $base.entry_user \
		-textvariable user

	label $base.label#3 \
		-text password=

	entry $base.entry_pass \
		-textvariable pass

	label $base.label#5 \
		-text scada

	button $base.button#8 \
		-command INFO \
		-text info

	label $base.label#4 \
		-text topology

	button $base.button#3 \
		-command TOPOtemp \
		-text tempobjects

	button $base.button#4 \
		-command TOPOgraph \
		-text graph

	button $base.button#5 \
		-command TOPOraw \
		-text raw

	button $base.button#6 \
		-command TOPOraw_network_state \
		-text raw/network/state

	button $base.button#7 \
		-command TOPOraw_network_state_broken \
		-text {/../state/ ?broken?}

	label $base.label#6 \
		-text api

	text $base.textoutput \
		-background SystemButtonFace \
		-borderwidth 4 \
		-cursor {} \
		-height 30 \
		-setgrid 1 \
		-width 1
	catch {
		$base.textoutput configure \
			-font {-*-MS Sans Serif-Medium-R-Normal-*-*-90-*-*-*-*-*-*}
	}

	scrollbar $base.scrolly \
		-orient v

	button $base.button#9 \
		-command DELlogs \
		-text {Clear windows..}

	button $base.button#10 \
		-command SaveFile \
		-text {Save file...}

	button $base.button#1 \
		-command OKbut \
		-text exit


	# Geometry management

	grid $base.label#1 -in $root	-row 1 -column 1  \
		-sticky nes
	grid $base.entry_server_host -in $root	-row 1 -column 2  \
		-sticky nesw
	grid $base.label#2 -in $root	-row 1 -column 3  \
		-sticky nes
	grid $base.entry_user -in $root	-row 1 -column 4  \
		-sticky nesw
	grid $base.label#3 -in $root	-row 1 -column 5  \
		-sticky nes
	grid $base.entry_pass -in $root	-row 1 -column 6  \
		-sticky nesw
	grid $base.label#5 -in $root	-row 2 -column 1  \
		-sticky nesw
	grid $base.button#8 -in $root	-row 2 -column 2  \
		-sticky nesw
	grid $base.label#4 -in $root	-row 3 -column 1  \
		-sticky nesw
	grid $base.button#3 -in $root	-row 3 -column 2  \
		-sticky nesw
	grid $base.button#4 -in $root	-row 3 -column 3  \
		-sticky nesw
	grid $base.button#5 -in $root	-row 3 -column 4  \
		-sticky nesw
	grid $base.button#6 -in $root	-row 3 -column 5  \
		-sticky nesw
	grid $base.button#7 -in $root	-row 3 -column 6  \
		-sticky nesw
	grid $base.label#6 -in $root	-row 4 -column 1  \
		-sticky nesw
	grid $base.textoutput -in $root	-row 5 -column 1  \
		-columnspan 6 \
		-sticky nesw
	grid $base.scrolly -in $root	-row 5 -column 7  \
		-sticky nesw
	grid $base.button#9 -in $root	-row 6 -column 1  \
		-sticky nesw
	grid $base.button#10 -in $root	-row 6 -column 2  \
		-sticky nesw
	grid $base.button#1 -in $root	-row 6 -column 6  \
		-sticky nesw

	# Resize behavior management

	grid rowconfigure $root 1 -weight 0 -minsize 18
	grid rowconfigure $root 2 -weight 0 -minsize 30
	grid rowconfigure $root 3 -weight 0 -minsize 30
	grid rowconfigure $root 4 -weight 0 -minsize 30
	grid rowconfigure $root 5 -weight 1 -minsize 636
	grid rowconfigure $root 6 -weight 0 -minsize 41
	grid columnconfigure $root 1 -weight 1 -minsize 187
	grid columnconfigure $root 2 -weight 1 -minsize 70
	grid columnconfigure $root 3 -weight 1 -minsize 116
	grid columnconfigure $root 4 -weight 1 -minsize 51
	grid columnconfigure $root 5 -weight 1 -minsize 113
	grid columnconfigure $root 6 -weight 1 -minsize 101
	grid columnconfigure $root 7 -weight 0 -minsize 2
# additional interface code
 ;##
 package require Tk
 ;##package require http
 package require rest ; #?1.0.1?
 package require json

#=======================================
proc Init { } {
#=======================================
 global user pass server_host
 set user admin  ; # admin nov_ema
 set pass passme ; #passme  qwertyqaz
 set server_host "192.168.101.144:8080" ; # "10.100.6.33:8080" "127.0.0.1:8080"
}
#=======================================
proc OKbut { } {
#=======================================
 exit ;
}
#=======================================
proc DELlogs { } {
#=======================================
 .textoutput delete 1.0 end;
}
#=======================================
proc SaveFile { } {
#=======================================
   set file [tk_getSaveFile -title "Save File" -parent .]
   if { $file == "" } {
        return; # they clicked cancel
   }
   set x [catch {set fid [open $file w+]}]
   set y [catch {puts $fid [.textoutput get 1.0 end-1c]}]
   set z [catch {close $fid}]
   if { $x || $y || $z || ![file exists $file] || ![file isfile $file] || ![file readable $file] } {
       tk_messageBox -parent . -icon error \
            -message "An error occurred while saving to \"$file\""
   } else {
       tk_messageBox -parent . -icon info -message "Save successful"
   }
 return 0 ;
}
#=======================================
proc OUTtext { msg } {
#=======================================
 .textoutput insert end "$msg\n"
}
#=======================================
proc TOPOraw { } {
#=======================================
 global user pass server_host
 OUTtext "Get RAW ..."
 OUTtext "Server: $server_host , u=$user , p=$pass"

 set err ""
 catch {
   set server(api) {
    method get
    auth basic
    format json
   }
   dict append server(api) url "http://${server_host}/rsdu/scada/api/app/topology/raw"

   rest::create_interface server
   server::basic_auth $user $pass
   set res [ server::api ]

   set ernull ""
 } err

 if {$err==""} {
   TOPOgraph_output $res
 } else {
   OUTtext "\n$err"
 }

}

#=======================================
proc TOPOgraph_output { ll } {
#=======================================
  set li [llength $ll ]
  OUTtext "\nElements=$li"
  foreach x $ll {
    set li [llength $x ]
    OUTtext "\nGroup()=$li"
    foreach y $x {
      OUTtext "  $y"
    }
  }
  OUTtext ""
}
#=======================================
proc TOPOgraph { } {
#=======================================
 global user pass server_host
 OUTtext "Get GRAPH ..."
 OUTtext "Server: $server_host , u=$user , p=$pass"

 set err ""
 catch {
   set server(api) {
     method get
     auth basic
     format json
     result json
   }
   dict append server(api) url "http://${server_host}/rsdu/scada/api/app/topology/graph"

   rest::create_interface server
   server::basic_auth $user $pass
   set res  [ server::api ]

   set ernull ""
 } err

 if {$err==""} {
   TOPOgraph_output $res
 } else {
   OUTtext "\n$err"
 }

}
#=======================================
proc TOPOtemp { } {
#=======================================
 global user pass server_host
 OUTtext "Get tempobjets ..."
 OUTtext "Server: $server_host , u=$user , p=$pass"

 set err ""
 catch {
   set server(api) {
     method get
     auth basic
     format json
   }
   dict append server(api) url "http://${server_host}/rsdu/scada/api/app/topology/tempobjects"

   rest::create_interface server
   server::basic_auth $user $pass
   set res [ server::api ]

   set ernull ""
 } err

 if {$err==""} {
   TOPOgraph_output $res
 } else {
   OUTtext "\n$err"
 }

}

#=======================================
proc get_equipment_by_guid { guid } {
#=======================================
 global user pass server_host

 set err ""
 catch {
   set cfg {
      method get
      format json
   }
   dict append cfg auth "basic $user $pass"

   set qw {}

   set jsonStr [rest::get "http://${server_host}/rsdu/scada/api/model/objstruct/objects/${guid}" $qw $cfg ]
   #set su [encoding convertfrom utf-8 $jsonStr ]
   #OUTtext $su
   set equipdict [json::json2dict $jsonStr]
   #set su [encoding convertfrom utf-8 $equipdict ]
   #OUTtext $su

   set ernull ""
 } err

 if {$err==""} {
   return $equipdict
 } else {
   return "{}"
 }
}

#=======================================
proc get_equipments_state { equipments_state } {
#=======================================
  set li [llength $equipments_state ]
  if {$li<=0} { return "" ; }

  set sD 0 ; set sUV 0 ; set sI 0 ; set sOther 0 ;
  foreach x $equipments_state {
    set state [dict get $x "State"]
    switch -- $state {
      Isolated {
        incr sI ;
      }
      UnderVoltage {
        incr sUV ;
      }
      Damaged {
        incr sD ;
      }
      default {
        incr sOther;
      }
    }
  } ; # for

  OUTtext "\nAll elements=$li  |  Isolated=$sI  UnderVoltage=$sUV  Damaged=$sD  Other=$sOther\n"

  foreach {item} $equipments_state {
    set state [dict get $item "State"]
    if {$state == "Damaged"} {
      set guid [dict get $item "ObjectId"]
      set find 1
      set idx 0
      while $find {
        set equipment_dict [ get_equipment_by_guid $guid ]

        set parent_uid ""
        if {[dict exists $equipment_dict "ParentUid"]} { set parent_uid [dict get $equipment_dict "ParentUid"] }
        set equipment_type {}
        if {[dict exists $equipment_dict "Type"]} { set equipment_type [dict get $equipment_dict "Type"] }

        if {$equipment_type=={}} { break ; }

        set equipment_type_alias [dict get $equipment_type "DefineAlias"]

        if {$parent_uid=="" || $equipment_type_alias == "OTYP_SUBSTATION" } { set find 0 }

        set name [dict get $equipment_dict "Name"]
        set equipment_type_name [dict get $equipment_type "Name"]

        if {$idx==0} {
          set su "${equipment_type_name}:${name} GUID:${guid}"
          set su [encoding convertfrom utf-8 $su ]
          OUTtext "+ ${su}"
        } else {
          set su "${equipment_type_name}:${name} GUID:${guid}"
          set su [encoding convertfrom utf-8 $su ]
          set s0 [string repeat " " $idx]
          OUTtext "${s0} - ${su}"
        }

        incr idx 1
        #break
        set guid $parent_uid
      }
    }
  }

}

#=======================================
proc TOPOgraph_outputstate { ll } {
#=======================================
  set li [llength $ll ]

  set sD 0 ; set sUV 0 ; set sI 0 ; set sOther 0 ;
  foreach x $ll {
    set state [dict get $x "State"]
    if {$state=="Isolated"} { 
      incr sI ; 
    } else {
      if {$state=="UnderVoltage"} { 
        incr sUV ; 
      } else {
         if {$state=="Damaged"} { 
           incr sD ; 
         } else {
           incr sOther;
         }
      }
    }
  } ; # for

  OUTtext "\nAll elements=$li  |  Isolated=$sI  UnderVoltage=$sUV  Damaged=$sD  Other=$sOther\n"

  set i 1
  foreach x $ll {
    set fr [ format "%-06d" $i ]
    #OUTtext "$fr | $x"
    OUTtext "$x"
    incr i
  }
  OUTtext ""
}
#=======================================
proc TOPOraw_network_state { } {
#=======================================
 global user pass server_host
 OUTtext "Get raw/network/state ..."
 OUTtext "Server: $server_host , u=$user , p=$pass"

 set err ""
 catch {
   set cfg {
      method get
      format json
      headers {
        Content-Type "application/json; charset=utf-8"
        Accept "application/json; charset=utf-8"
      }
   }
   dict append cfg auth "basic $user $pass"

   set qw {}
   set jsonStr [rest::get "http://${server_host}/rsdu/scada/api/app/topology/raw/network/state" $qw $cfg ]
   set dj [json::json2dict $jsonStr] ; #

   set ernull ""
 } err

 if {$err==""} {
   TOPOgraph_outputstate $dj
 } else {
   OUTtext  "\n$err"
 }

}
#=======================================
proc TOPOraw_network_state_broken { } {
#=======================================
 global user pass server_host
 OUTtext "Get raw/network/state/broken ..."
 OUTtext "Server: $server_host , u=$user , p=$pass"

 set err ""
 catch {
   set cfg {
      method get
      format json
      headers {
        Content-Type "application/json; charset=utf-8"
        Accept "application/json; charset=utf-8"
      }
   }
   dict append cfg auth "basic $user $pass"

   set qw {}
   #dict append qw ObjectTypes "OTYP_GROUNDER OTYP_GROUND_SWITCH OTYP_SHORTING_SWITCH"
   #set qw  "js=\{ObjectTypes:\[ OTYP_GROUNDER OTYP_GROUND_SWITCH OTYP_SHORTING_SWITCH \] \}"

   set jsonStr [rest::get "http://${server_host}/rsdu/scada/api/app/topology/raw/network/state" $qw $cfg ]
   set dj [json::json2dict $jsonStr] ; #

   set ernull ""
 } err

 if {$err==""} {
# for Debug:
;#set djt [list {ObjectId 000db6c1-8254-4596-87da-4c88c41c6717 State Isolated} 
;#{ObjectId 002472e5-469a-ff47-ba1d-5f0faabf97db State UnderVoltage} 
;#{ObjectId 00fdfa42-66ac-4267-ab7d-857f61706e9a State Damaged}]

   get_equipments_state $dj

 } else {
   OUTtext  "\n$err"
 }

}
#=======================================
proc INFO { } {
#=======================================
 global user pass server_host
 OUTtext "Get info ..."
 OUTtext "Server: $server_host , u=$user , p=$pass"

 set err ""
 catch {
    set cfg {
        method get
        format json
        headers {
          Content-Type "application/json; charset=utf-8"
          Accept "application/json; charset=utf-8"
        }
   }
   dict append cfg auth "basic $user $pass"

   set res [rest::simple http://${server_host}/rsdu/scada/api/app/info {} $cfg ]
   set res [encoding convertfrom utf-8 $res ]

   set ernull ""
 } err

 if {$err==""} {
   OUTtext "\n$res"
 } else {
   OUTtext "\n$err"
 }

}

#=======================================
#     catch {destroy $w}
#     toplevel $w
$base.textoutput configure -yscrollcommand [list $base.scrolly set]
$base.scrolly configure  -command [list $base.textoutput yview]
$base.textoutput delete 1.0 end

Init

set t1 [ clock format [ clock seconds ] -format "%Y-%m-%d %H:%M:%S" ]
OUTtext "\nTime = $t1\n"

encoding system "utf-8"

#=======================================




# end additional interface code

}


# Allow interface to be run "stand-alone" for testing


	    wm title . "SCADA API"
	    serverApi_ui .