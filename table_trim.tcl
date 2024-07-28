
# Подключаем 2-а пакета: для работы с деревом + для подключения к БД через ODBC
package require tclodbc

global tns usr pwd
  set tns "rsdu2" ; #"rsdu2" "Postrsdu5" "poli24"
  set usr "rsduadmin" ; #  admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz

#=============================================
proc TableTrim { db2 tbl colid colname toBD } {
#=============================================

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
      puts "---- ${id}=${idName1}=${idName2}="
      incr fl;
      set si "update $tbl set $colname = '${idName2}' where $colid = $id ;"

      if {$toBD==1} {
        puts $si
        $db2 $si
      } else {
        puts "--${si}"
      }
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

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\n----start = $t1\n"

# Устанавливаем соединение к БД
  database db $tns $usr $pwd
#db set autocommit off

  TableTrim db "obj_tree" "id" "name" 1
  TableTrim db "obj_tree" "id" "alias" 1
  TableTrim db "meas_list" "id" "name" 1
  TableTrim db "meas_list" "id" "alias" 1
  TableTrim db "da_dev_desc" "id" "name" 1
  TableTrim db "da_dev_desc" "id" "alias" 1
  TableTrim db "da_param" "id" "name" 1
  TableTrim db "da_param" "id" "alias" 1
  TableTrim db "RPT_LST" "id" "name" 1


# Закрываем соединение к БД
  db commit
  db disconnect

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\n----end = $t1"

  return
}


main












