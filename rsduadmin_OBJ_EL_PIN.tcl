#
#
package require tclodbc

global tns usr pwd
  set tns "RSDU2BelGRES" ; # "rsdu2"
  set usr "rsduadmin" ; #  admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz

# ===============================================
proc LogWrite  { s } {
# ===============================================
  global rf
  if {![info exists rf]} { return }
  if {$rf==""} { return }
  puts $rf $s
}
# ===============================================
proc LogFlush  { } {
# ===============================================
  global rf
  if {![info exists rf]} { return }
  if {$rf==""} { return }
  flush $rf
}

#
#CREATE TABLE OBJ_EL_PIN (
#    ID           DECIMAL        NOT NULL,
#    ID_OBJ       DECIMAL,
#    PIN_NUM      DECIMAL,
#    ID_CONN_NODE DECIMAL,
#    GUID         TEXT,
#    NAME         NVARCHAR (255)
#);
#
#=============================================
proc OBJ_EL_PIN { } {
#=============================================

  set count  0

  set cntOBJ 0
  set str1 "SELECT count(ID) FROM OBJ_EL_PIN WHERE GUID is NULL"
  foreach {x} [ db $str1 ] {
    set cntOBJ [ lindex $x 0 ]
  }
  puts "OBJ_EL_PIN cnt null = $cntOBJ"

  if {$cntOBJ==0} { return ; }

         #1201ad92-72d3-43e6-9ebb-0b0e2ec80880
         #3af5dc9a-1b6c-49ad-bcfd-513ee71f9376
  set gi "3af5dc9a1b6c49adbcfd513ee71f"
  set v 1

  set str1 "SELECT ID FROM OBJ_EL_PIN WHERE GUID is NULL"
  foreach {x} [ db $str1 ] {
    set ID [ lindex $x 0 ]

    set sf [ format "%04d" $v]
    set gif "$gi$sf"

    set s1 "UPDATE OBJ_EL_PIN SET GUID='$gif' , NAME='Зажим0' WHERE ID=$ID ;"
    #db $s1

    LogWrite "\n$s1"

    incr v
  }
  #db commit

  return 0 ;
}


proc main { } {
#
  global tns usr pwd
  global db
  global rf

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\n----start = $t1\n"


  set tN [ clock format [ clock seconds ] -format "%Y%m%d_%H%M%S" ]
# лог - файл
  set ph [info script]
  if {$ph==""} {
    set ph ${tns}_sqlite_${tN}.log
  } else {
    set ph [ file rootname $ph ]_${tN}.log
  }
  set rf [ open $ph "w+"  ]

  LogWrite "--START=$t1\n"

# Устанавливаем соединение к БД
  database db $tns $usr $pwd
  #db set autocommit off

  OBJ_EL_PIN

# Закрываем соединение к БД
  #db commit
  db disconnect

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\n----end = $t1\n"

  LogWrite "\n--END=$t1"

  return
}


main

