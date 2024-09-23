
# Подключаем пакет: для подключения к БД через ODBC
package require tclodbc

global tns usr pwd
  set tns "rsdu2" ; #"rsdu2" "Postrsdu5" "poli24"
  set usr "rsduadmin" ; #  admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz

global rf

proc LogWrite  { s } {
  global rf
  if {![info exists rf]} { return }
  if {$rf==""} { return }
  puts $rf $s
}

# --
proc checkTable { db2 tblname col } {
# --
  set strSQL1 "SELECT count($col) FROM $tblname"
  set df ""
  set err ""
  catch {
    set df [ $db2 $strSQL1 ]
    set p ""
  } err
  #puts "-- $tblname  -- $df "
  if {$err!=""} { return 0 ; }
  return 1 ;
}

#=============================================
proc TableTrim { db2 tbl colid colname toBD } {
#=============================================

  if {[ checkTable $db2 $tbl $colname ]==0} {
    return 0
  }
  if {[ checkTable $db2 $tbl $colid ]==0} {
    return 0
  }


  set str1 "select $colid , $colname from $tbl ;"

  set count  0
  foreach {x} [ $db2 $str1 ] {
    set id       [ lindex $x 0 ]
    set idName1  [ lindex $x 1 ]

    set idName2  [ string trim $idName1 ]
    set fl 0

    set l1 [ string length $idName1  ]
    set l2 [ string length $idName2  ]
    if {$l1!=$l2} {
      LogWrite "-- -- ;${id};${idName1};${idName2};"
      incr fl;
      set si "update $tbl set $colname = '${idName2}' where $colid = $id ;"

      #if {$toBD==1} {
      #  $db2 $si
      #}

      LogWrite "${si}"
      incr count;

    }

    #puts ${x}
  }

  puts "\n---- count=$count" ;
  if {$toBD!=1} { puts "\n----NOT SAVE TO BD" ; }

  return 0 ;
}

#=============================================
proc main { } {
#=============================================
  global tns usr pwd
  global rf

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\n----start = $t1\n"

  # лог - файл
  set ph [info script]
  if {$ph==""} {
    set ph table_trim_${t1}.log
  } else {
    set ph [file rootname $ph ]_${t1}.log
  }

  set rf [ open $ph "w+"  ]

# Устанавливаем соединение к БД
  database db $tns $usr $pwd
#db set autocommit off

  TableTrim db "obj_tree" "id" "name" 0
  TableTrim db "obj_tree" "id" "alias" 0
  TableTrim db "meas_list" "id" "name" 0
  TableTrim db "meas_list" "id" "alias" 0
  TableTrim db "da_dev_desc" "id" "name" 0
#  TableTrim db "da_dev_desc" "id" "alias" 0
  TableTrim db "da_param" "id" "name" 0
  TableTrim db "da_param" "id" "alias" 0
  TableTrim db "RPT_LST" "id" "name" 0

#db commit
# Закрываем соединение к БД
  db disconnect

  flush $rf
  close $rf

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\n----end = $t1"

  return
}


main












