
# Подключаем 2-а пакета: для работы с деревом + для подключения к БД через ODBC
package require tclodbc

global tns usr pwd
  set tns "rsdu2" ; #"rsdu2" "Postrsdu5" "poli24"
  set usr "rsduadmin" ; #  admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz

#=============================================
proc TableTrim { db2 tbl colname toBD } {
#=============================================
  set count  0

  set str1 "select $colname from $tbl order by $colname"

  foreach {x} [ $db2 $str1 ] {
    set idName1  [ lindex $x 0 ]
    set idName2  [ string trim $idName1 ]
  
    set fl 0
    set s0 "update $tbl set "
    set s1 ""
    set s2 ""
    set s3 ""

    set l1 [ string length $idName1  ]
    set l2 [ string length $idName2  ]
    if {$l1!=$l2} {
      puts "---- =${idName1}=${idName2}="
      set s1 [ format "%s='%s' " $colname $idName2 ]
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

  TableTrim db "obj_tree" "name" 0
  TableTrim db "meas_list" "name" 0
  TableTrim db "da_dev_desc" "name" 0
  TableTrim db "da_param" "name" 0
  #TableTrim db "RPT_LST" "name" 0
  #TableTrim db "sys_otyp" "name" 0

# Закрываем соединение к БД
  db commit
  db disconnect

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\n----end = $t1"

  return
}


main












