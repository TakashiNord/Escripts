

package require tclodbc
package require sqlite3

proc LogWrite  { s } {
  global rf
  if {![info exists rf]} { return }
  if {$rf==""} { return }
  puts $rf $s
}

proc GetElem { fpid level } {
  global db1

  set sql4 "Select ID, ID_PARENT ,ID_TYPE, NAME , ALIAS from  OBJECTS_INPts3 where ID_PARENT=$fpid"

#  db1 eval $sql4 recs2 {
#    set sz [ array size recs2 ]
# if {$sz<=1} { break ; }
#    set st [ string repeat " " $level ]
#    LogWrite "$st $recs2(id) $recs2(name)"
# set p [ expr $level+1 ]
#    GetElem $recs2(pid) $p
#  }

  set st [ string repeat " " $level ]
  set recs2 [ db1 eval $sql4 ] ;
  for { set i 0} {$i<[llength $recs2]} {incr i 5} {
    set id [lindex $recs2 $i]
    set name [lindex $recs2 [expr $i+3]]
	set alias [lindex $recs2 [expr $i+4]]
	
	  set header [format "%-91s|" " " ]
	  
	  set sql34 "Select OBJ_REF , NAME, ALIAS from  OBJECTS_LINKts3 where ID_SBS=4 and ID_OBJ=$id"
	  set r1 [ db1 eval $sql34 ] ;
	  for { set j 0} {$j<[llength $r1]} {incr j 3} {
	    set ref [lindex $r1 $j]
        set refname [lindex $r1 [expr $j+1]]
		set refalias [lindex $r1 [expr $j+2]]
		set header [format "%-10s  %-30s  %-46s|" $ref  $refname  $refalias ]
		LogWrite "insert into OBJECTS_LINK (ID_SBS,ID_OBJ,OBJ_REF,NAME,ALIAS,ID_TYPE) values ( 4,$id,'$ref','$refname','$refalias', null)"
		break 
	  }
	
	
    LogWrite "$header$st $id  $alias  $name"
    set p [ expr $level+2 ]
    set ret [ GetElem $id $p ]
  }

  return 0
}


# ===============================================
proc  main { } {
# ===============================================
  global db1
  global db2
  global own
  global rf

  # avtorization
  set tns "rsdu2"
  set usr "rsduadmin" ; # sys "rsduadmin" admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nstart = $t1"

# Устанавливаем соединение к БД
#  database db2 $tns $usr $pwd
#  db2 set autocommit off

# открываем - создаем бд
  set phdb "D:\\DBsqlite\\rsdu2_to6.db"

  sqlite3 db1 $phdb ;# associate the SQLite database with the object


  set PowerObject [ list  1180875 ]

  foreach PowerObjectId $PowerObject {

    set namefile "obj"

    # лог - файл
    set ph [info script]
    set md "a+"
    if {$ph==""} {
       set ph inp_zvkdgk.log
    } else {
       set p1 [ file dirname $ph ] ; # [file dirname /foo/bar/grill.txt] -> /foo/bar
       set ph [ file join $p1 ${ph}.log ]
       #set ph [file rootname $ph ].log
       set md "w+"
    }
    set rf [ open $ph $md ]


    set sql33 "Select ID, ID_PARENT ,ID_TYPE, NAME, ALIAS from  OBJECTS_INPts3 where ID_PARENT is null " ; # and ID=$PowerObjectId "

    global recs1
    # building tree
    set recs1 [ db1 eval $sql33 ] ;
    #LogWrite $recs1
    set st ""
    for { set i 0} {$i<[llength $recs1]} {incr i 5} {
      set id [lindex $recs1 $i]
      set name [lindex $recs1 [expr $i+3]]
	  set alias [lindex $recs1 [expr $i+4]]
	  
	  set header [format "%-91s|" " " ]
	  
	  set sql34 "Select OBJ_REF , NAME, ALIAS from  OBJECTS_LINKts3 where ID_SBS=4 and ID_OBJ=$id"
	  set r1 [ db1 eval $sql34 ] ;
	  for { set j 0} {$j<[llength $r1]} {incr j 3} {
	    set ref [lindex $r1 $j]
        set refname [lindex $r1 [expr $j+1]]
		set refalias [lindex $r1 [expr $j+2]]
		set header [format "%-10s  %-30s  %-46s|" $ref  $refname  $refalias ]
		LogWrite "insert into OBJECTS_LINK (ID_SBS,ID_OBJ,OBJ_REF,NAME,ALIAS,ID_TYPE) values ( 4,$id,'$ref','$refname','$refalias', null)"
		break 
	  }
	  
      LogWrite "\n$header$st $id  $alias  $name"
      set ret [ GetElem $id 1 ]
    }


    close $rf

  }

  db1 close

# Закрываем соединение к БД
#  db2 commit
#  db2 disconnect

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nend = $t1"



  return 0 ;
}

  main
