
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
proc paramDB { db2 } {
#=============================================

set strSQL1 "select id,name as sys_tree21_topname from sys_tree21 where id_parent is null;"

set str1 "SELECT ad.NAME as DESCS,as1.ID_USER,su.LOGIN,rip.NAME,asi.VALUE,rip.DESCRIPTION \
 FROM AD_SINFO_INI asi, AD_DIR ad, RSDU_INI_PARAM rip, AD_SINFO as1, S_USERS su \
 WHERE asi.ID_SERVER_NODE=ad.id and asi.ID_INI_PARAM=rip.id \
   and asi.ID_SERVER_NODE=as1.ID_SERVER_NODE \
   and su.ID=as1.ID_USER \
 ORDER BY asi.ID_SERVER_NODE "

set str2 "SELECT u.ID ID_USER, u.login login, r.NAME parameter, i.VALUE VALUE \
      FROM ad_sinfo_ini i, ad_sinfo s, s_users u, rsdu_ini_param r \
     WHERE s.id_server_node = i.id_server_node \
       AND u.ID = s.id_user \
       AND r.ID = i.id_ini_param "

set str3 "select num , name , value , description from v\$parameter"

  set count  0

  foreach {x} [ $db2 $strSQL1 ] {
    set l [ llength $x ]
    set s0 ""
    foreach {p} $x {
      append s0 $p
      append s0 "   "
    }
    set s0 [ string trim $s0 ]
    LogWrite "${s0}"
  }

  LogWrite "\n\n"

  foreach {x} [ $db2 $str1 ] {
    set l [ llength $x ]
    set s0 ""
    foreach {p} $x {
      append s0 $p
      append s0 "   "
    }
    set s0 [ string trim $s0 ]
    LogWrite "${s0}"
  }

  LogWrite "\n\n"

  foreach {x} [ $db2 $str2 ] {
    set l [ llength $x ]
    set s0 ""
    foreach {p} $x {
      append s0 $p
      append s0 "       "
    }
    set s0 [ string trim $s0 ]
    LogWrite "${s0}"
  }

  LogWrite "\n\n"

  foreach {x} [ $db2 $str3 ] {
    set l [ llength $x ]
    set s0 ""
    foreach {p} $x {
      append s0 $p
      append s0 "            "
    }
    set s0 [ string trim $s0 ]
    LogWrite "${s0}"
  }

  LogWrite "\n\n"

  return 0 ;
}

#=============================================
proc main { } {
#=============================================
  global tns usr pwd
  global rf

  set t1 [ clock format [ clock seconds ] -format "%Y%m%d_%H%M%S" ]
  puts "\n----start = $t1\n"

  # лог - файл
  set ph [info script]
  if {$ph==""} {
    set ph param_db_${t1}.log
  } else {
    set ph [file rootname $ph ]_${t1}.log
  }

  set rf [ open $ph "w+"  ]

# Устанавливаем соединение к БД
  database db $tns $usr $pwd
#db set autocommit off

  paramDB db

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












