

global rf

proc LogWrite  { s } {
  global rf
  if {![info exists rf]} { return }
  if {$rf==""} { return }
  puts $rf $s
}

#=============================================
proc main { } {
#=============================================
  global rf

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\n----start = $t1\n"

  # лог - файл
  set ph [info script]
  if {$ph==""} {
    set ph rd_${t1}.log
  } else {
    set ph [file rootname $ph ]_${t1}.log
  }

  set rf [ open $ph "w+"  ]

  set ob [ list ]
  
  set rf1 [ open "table_trim_OBJ_TREE_find.log" "r"  ]
  fconfigure $rf1 -encoding unicode
  while { [gets $rf1 data] >= 0 } {
     lappend ob $data
	 #puts $data
  }
  close $rf1
  
  set len [ llength $ob ]
  puts "len(ob)= $len "
  
 
  set rf2 [ open "table_trim_obj_3w2.txt" "r"  ]
  fconfigure $rf2 -encoding unicode
  while { [gets $rf2 data] >= 0 } {
     set ld [ split $data ]
	 set len [ llength $ld ]
	 set i [ expr $len - 2 ]
	 if {$i<=0} { continue; }
	 set param [ lindex $ld $i ]
	 set st [lsearch -regexp $ob ${param} ]
	 if {$st >= 0} {
	   #"Column 1 "
	   set paramID [ lindex $ob [ expr $st-10 ] ]
	   set paramID2 [ string map -nocase {"Column 1 " ""} $paramID ]
	   
	   set paramN [ lindex $ob [ expr $st-5 ] ]
	   #"Column 6 "
	   set paramN2 [ string map -nocase {"Column 6 " ""} $paramN ]
	   #"Column 7 "
	   set paramA [ lindex $ob [ expr $st-4 ] ]
	   set paramA2 [ string map -nocase {"Column 7 " ""} $paramA ]
	   
	   #LogWrite  "$paramID2 = '${paramN2}' $paramA2"
	   set sn1 [ string trim $paramN2 ]
       set sn2 [ string trim $paramA2 ]	   

	   set si "update OBJ_TREE set  NAME='${sn1}' where id= $paramID2 ;"
	   LogWrite $si
	   set si "update OBJ_TREE set  ALIAS='${sn2}' where id= $paramID2 ;"
	   LogWrite $si
	   
     }
  }
  close $rf2




  flush $rf
  close $rf

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\n----end = $t1"

  return
}


main
