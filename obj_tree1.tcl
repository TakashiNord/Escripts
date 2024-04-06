
package require tclodbc

puts "-- Start --"


proc LogWrite  { s } {
  global rf
  if {![info exists rf]} { return }
  if {$rf==""} { return }
  puts $rf $s
}



proc GetList { fpid header } {
  global db1

#  set sql4 "Select ID,ID_PARENT,ID_TYPE,NAME,ALIAS from OBJ_TREE where ID_PARENT=$fpid"

#  foreach {r1} [ db1 $sql4 ] {
#    set id [ lindex $r1 0 ]
#    set name [ lindex $r1 3 ]

#    set str "${header};${id};${name}"
#    LogWrite $str

#  }

  return 0
}



proc GetElem { fpid header } {
  global db1
  global Num

  set sql4 "Select ID,ID_PARENT,ID_TYPE,NAME,ALIAS from OBJ_TREE where ID_PARENT=$fpid"

  foreach {r1} [ db1 $sql4 ] {
    set id [ lindex $r1 0 ]
    set name [ lindex $r1 3 ]

    set str "${header};${id};${name}"
    LogWrite $str
    GetList $id "${str}"
    set ret [ GetElem $id $str ]
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
  global Num

  # avtorization
  set tns "rsdu2"
  set usr "rsduadmin" ; # sys "rsduadmin" admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz

  set t1 [ clock format [ clock seconds ] -format "%T" ]

  set t11 [ clock format [ clock seconds ] -format "%Y%m%d_%H%M%S" ]

  #puts "\nstart = $t1"

# Óñòàíàâëèâàåì ñîåäèíåíèå ê ÁÄ
  database db1 $tns $usr $pwd
#  db1 set autocommit off

  set namefile "obj"

  # ëîã - ôàéë
  set ph [info script]
  set md "a+"
  if {$ph==""} {
     set ph obj_tree_${t11}.log
  } else {
     set p1 [ file dirname $ph ] ; # [file dirname /foo/bar/grill.txt] -> /foo/bar
     set ph [ file join $p1 ${ph} ]_${t11}.log
     set md "w+"
  }

# -------------------------------------------------------------------------------------------------

  set rf [ open $ph $md ]
  #set rf stdout ; # вывод в стандартное устройство

# -------------------------------------------------------------------------------------------------

  set sql33 "Select ID,ID_PARENT,NAME FROM OBJ_TREE where ID_PARENT is NULL" ;

  foreach {r1} [ db1 $sql33 ] {
     set id [ lindex $r1 0 ]
     set name [ lindex $r1 2 ]
     set nm "$id;$name"
     LogWrite $nm
     GetList $id "${nm}"
     set ret [ GetElem $id $nm ]
  }


# ===============================================
# Закрываем соединение к БД
#  db1 commit
  db1 disconnect

  close $rf

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nend = $t1"

  return 0 ;
}

  main

  puts "-- End --"