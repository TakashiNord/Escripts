

package require tclodbc
package require sqlite3

set tns "rsdu2"
set usr "rsduadmin" ; #  admin  nov_ema
set pwd "passme" ; # passme  qwertyqaz

puts "-- Start --"

# лог - файл
  set ph [info script]
  if {$ph==""} {
    set ph rsduadmin_ast_guid.log
  } else {
    set ph [file rootname $ph ].log
  }

proc LogWrite  { s } {
  global rf
  if {![info exists rf]} { return }
  if {$rf==""} { return }
  puts $rf $s
}

 set rf [ open $ph "w+"  ]

# Устанавливаем соединение к БД
 database db2 $tns $usr $pwd
 db2 set autocommit off

 set owner "RSDUADMIN"

# Устанавливаем РОЛЬ
# по умолчанию = BASE_EXT_CONNECT_OIK CONNECT => SBOR_STAND_READ
  if {$usr!="rsduadmin"} {
    db2 "SET ROLE SBOR_STAND_READ , BASE_STAND_READ"
    db2 "select * from session_roles"
  }


#CREATE TABLE AST_ORG
#
#  ID          NUMBER(11),
#  GUID        RAW(16),
#  ID_PARENT   NUMBER(11),
#  ID_TYPE     NUMBER(11) CONSTRAINT AST_ORG_ID_TYPE_NN NOT NULL,
#  NAME        VARCHAR2(255 CHAR),
#  ALIAS       VARCHAR2(255 CHAR),
#  ID_FILEWAV  NUMBER(11),
#  DATE_MOD    NUMBER(11)
#

#CREATE TABLE AST_CNT
#
#  ID          NUMBER(11),
#  GUID        RAW(16),
#  ID_PARENT   NUMBER(11),
#  ID_TYPE     NUMBER(11) CONSTRAINT AST_CNT_ID_TYPE_NN NOT NULL,
#  NAME        VARCHAR2(255 CHAR),
#  ALIAS       VARCHAR2(255 CHAR),
#  ID_FILEWAV  NUMBER(11),
#  DATE_MOD    NUMBER(11)
#



proc T_GROUPS { strSQL ID level } {
    global db2
	set cnt 0
	set strSQL2 [ format $strSQL $ID ]
    foreach {r2} [ db2 $strSQL2 ] {
      set ID2 [ lindex $r2 0 ]
      set GUID [ lindex $r2 1 ]
      set NAME [ lindex $r2 2 ]
      set ALIAS [ lindex $r2 3 ]

	  set s2 "$ID2 ,$NAME = $GUID"
	  set l2 [ string length $s2 ]

	  set s0 [ string repeat \t $level ]
	  puts "$s0$s2"
	  LogWrite "$s0$s2"
	  incr cnt

	  ##_LIST $ID2 $l2

	  set p [ expr $level+1 ]
	  set ret [ T_GROUPS $strSQL $ID2 $p ]

	}

	return $cnt
}

# ===============================================
  # формируем строки, создаем таблицу, копируем данные - последовательно.

  set strSQL1 "SELECT ao.ID, cast(ao.GUID  as varchar(256)), ao.NAME, ao.ALIAS  FROM AST_CNT ao \
      WHERE COALESCE( ao.ID_PARENT, 0, 0)=0 ORDER BY ao.ID"

  foreach {r1} [ db2 $strSQL1 ] {
    set ID1 [ lindex $r1 0 ]
    set GUID [ lindex $r1 1 ]
    set NAME [ lindex $r1 2 ]
    set ALIAS [ lindex $r1 3 ]

	set s1 "$ID1 ,$NAME = $GUID"
	set l1 [ string length $s1 ]
	puts $s1
	LogWrite $s1

	set strSQL "SELECT ao.ID, cast(ao.GUID  as varchar(256)), ao.NAME, ao.ALIAS  FROM AST_CNT ao WHERE ao.ID_PARENT=%s ORDER BY ao.ID"
	set ret1 [ T_GROUPS $strSQL $ID1 1 ]

    puts "--"
	LogWrite "--"
  }

  flush $rf


  set strSQL1 "SELECT ao.ID, cast(ao.GUID  as varchar(256)), ao.NAME, ao.ALIAS  FROM AST_ORG ao \
     WHERE COALESCE( ao.ID_PARENT, 0, 0)=0 ORDER BY ao.ID"

  foreach {r1} [ db2 $strSQL1 ] {
    set ID1 [ lindex $r1 0 ]
    set GUID [ lindex $r1 1 ]
    set NAME [ lindex $r1 2 ]
    set ALIAS [ lindex $r1 3 ]

	set s1 "$ID1 ,$NAME = $GUID"
	set l1 [ string length $s1 ]
	puts $s1
	LogWrite $s1

	set strSQL "SELECT ao.ID, cast(ao.GUID  as varchar(256)), ao.NAME, ao.ALIAS  FROM AST_ORG ao WHERE ao.ID_PARENT=%s ORDER BY ao.ID"
	set ret1 [ T_GROUPS $strSQL $ID1 1 ]

    puts "--"
	LogWrite "--"
  }

  flush $rf


# ===============================================
# Закрываем соединение к БД
#  db2 commit
  db2 disconnect

  close $rf

  puts "-- End --"
