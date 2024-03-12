
# Подключаем 2-а пакета: для работы с деревом + для подключения к БД через ODBC
package require tclodbc

#=============================================
proc TableTrim { tbl toBD alias } {
#=============================================
  set tns "rsdu2"
  set usr "rsduadmin" ; #  admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\n----start = $t1\n"

# Устанавливаем соединение к БД
  database db $tns $usr $pwd
#db set autocommit off

  set count  0
  set str1 "select id, name"
  if {$alias==1} {
    set str1 "${str1} , alias"
  }
  set str1 "${str1} from $tbl order by name"

  foreach {x} [ db $str1 ] {
  set id [ lindex $x 0 ]
  set idName1  [ lindex $x 1 ]
  set idNameA1  [ lindex $x 2 ]

  set idName2  [ string trim $idName1 ]
  set idNameA2  [ string trim $idNameA1 ]

    set fl 0
  set s0 "update $tbl set "
  set s1 ""
  set s2 ""
  set s3 ""

  set l1 [ string length $idName1  ]
  set l2 [ string length $idName2  ]
  if {$l1!=$l2} {
      puts "---- ${id}=${idName1}=${idName2}="
    set s1 [ format "name='%s' "  $idName2 ]
    incr fl;
    }

  set l1 [ string length $idNameA1  ]
  set l2 [ string length $idNameA2  ]
  if {$l1!=$l2} {
      puts "---- ${id}=${idNameA1}=${idNameA2}="
    set s2 [ format " alias='%s' " $idNameA2 ]
    incr fl;
    }

  if {$fl>0} {
    set si [ format " where id=%s" $id ]
    set sl1 [ string length $s1  ]
    set sl2 [ string length $s2  ]
    if {$sl1>0 && $sl2>0} { set s3 " , " }
    set s "${s0}${s1}${s3}${s2}${si}"
    if {$toBD==1} {
      puts $s
      db $s
    } else {
      puts "--${s}"
    }
    incr count;
    }

  #puts ${x}
  }

  puts "\n---- count=$count" ;
  if {$toBD!=1} { puts "\n----NOT SAVE TO BD" ; }

# Закрываем соединение к БД
  db commit
  db disconnect

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\n----end = $t1"

  return 0 ;
}


proc main { } {
  # TableTrim  tbl toBD alias
  TableTrim "obj_tree" 0 1
  TableTrim "meas_list" 0 1
  TableTrim "da_dev_desc" 0 0
  TableTrim "da_param" 0 1
  #TableTrim "RPT_LST" 0 1
  #TableTrim "sys_otyp" 0 1
  return
}


main












