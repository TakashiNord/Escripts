

package require tclodbc
package require sqlite3

set tns "rsdu2"
set usr "rsduadmin" ; #  admin  nov_ema
set pwd "passme" ; # passme  qwertyqaz

puts "-- Start --"

# лог - файл
  set ph [info script]
  if {$ph==""} {
    set ph rsduadmin_dg_guid.log
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


#CREATE TABLE DG_GROUPS
#
#  ID          NUMBER(11),
#  GUID        RAW(16),
#  ID_PARENT   NUMBER(11),
#  ID_TYPE     NUMBER(11) CONSTRAINT DG_GROUPS_ID_TYPE_NN NOT NULL,
#  NAME        VARCHAR2(255 CHAR),
#  ALIAS       VARCHAR2(255 CHAR),
#  ID_FILEWAV  NUMBER(11)
#

#CREATE TABLE DG_LIST
#
#  ID          NUMBER(11),
#  GUID        RAW(16),
#  ID_TYPE     NUMBER(11) CONSTRAINT DG_LIST_ID_TYPE_NN NOT NULL,
#  ID_NODE     NUMBER(11) CONSTRAINT DG_LIST_ID_NODE_NN NOT NULL,
#  NAME        VARCHAR2(255 CHAR),
#  ALIAS       VARCHAR2(255 CHAR),
#  ID_FILEWAV  NUMBER(11)
#

proc DG_LIST { ID level } {
    global db2
	set cnt 0

	#set strSQL2 "SELECT ID, cast(GUID  as varchar(256)), NAME, ALIAS FROM DG_LIST WHERE ID_NODE=$ID ORDER BY ID"
	set strSQL2 "SELECT dl.ID, cast(dl.GUID  as varchar(256)), dl.NAME, dl.ALIAS , smt.NAME FROM DG_LIST dl, SYS_MEAS_TYPES smt \
	   WHERE dl.ID_TYPE = smt.ID  AND dl.ID_NODE=$ID ORDER BY dl.ID"
    foreach {r2} [ db2 $strSQL2 ] {
      set ID2 [ lindex $r2 0 ]
      set GUID [ lindex $r2 1 ]
      set NAME [ lindex $r2 2 ]
      set ALIAS [ lindex $r2 3 ]
	  set TYPE [ lindex $r2 4 ]
	  set s2 "$ID2 ,($TYPE),$NAME = $GUID"

	  set s0 [ string repeat " " $level ]
	  puts "$s0 PARAM: $s2"
	  LogWrite "$s0 PARAM: $s2"
	  incr cnt

	}
	return $cnt
}


proc DG_GROUPS { ID level } {
    global db2
	set cnt 0

	##set strSQL2 "SELECT ID, utl_raw.cast_to_varchar2(GUID), NAME, ALIAS FROM DG_GROUPS WHERE ID_PARENT=$ID"
	#set strSQL2 "SELECT ID, cast(GUID  as varchar(256)), NAME, ALIAS FROM DG_GROUPS WHERE ID_PARENT=$ID ORDER BY ID"

    set strSQL2 "SELECT dg.ID, cast(dg.GUID  as varchar(256)), dg.NAME, dg.ALIAS, so.NAME as Type FROM DG_GROUPS dg, SYS_OTYP so \
      WHERE dg.ID_TYPE = so.ID and dg.ID_PARENT=$ID ORDER BY dg.ID"

    foreach {r2} [ db2 $strSQL2 ] {
      set ID2 [ lindex $r2 0 ]
      set GUID [ lindex $r2 1 ]
      set NAME [ lindex $r2 2 ]
      set ALIAS [ lindex $r2 3 ]
	  set TYPE [ lindex $r2 4 ]
	  set s2 "$ID2 ,($TYPE),$NAME = $GUID"
	  set l2 [ string length $s2 ]

	  set s0 [ string repeat \t $level ]
	  puts "$s0$s2"
	  LogWrite "$s0$s2"
	  incr cnt

	  DG_LIST $ID2 $l2

	  set p [ expr $level+1 ]
	  set ret [ DG_GROUPS $ID2 $p ]

	}

	return $cnt
}

# ===============================================
  # формируем строки, создаем таблицу, копируем данные - последовательно.

  set strSQL1 "SELECT dg.ID, cast(dg.GUID  as varchar(256)), dg.NAME, dg.ALIAS, so.NAME as Type FROM DG_GROUPS dg, SYS_OTYP so \
  WHERE COALESCE( dg.ID_PARENT, 0, 0)=0 and dg.ID_TYPE = so.ID ORDER BY dg.ID"

  #set strSQL1 "SELECT ID, cast(GUID  as varchar(256)), NAME, ALIAS FROM DG_GROUPS WHERE COALESCE( ID_PARENT, 0, 0)=0 ORDER BY ID "
  ##set strSQL1 "SELECT ID, utl_raw.cast_to_varchar2(GUID), NAME, ALIAS FROM DG_GROUPS WHERE COALESCE( ID_PARENT, 0, 0)=0 ORDER BY ID"
  foreach {r1} [ db2 $strSQL1 ] {
    set ID1 [ lindex $r1 0 ]
    set GUID [ lindex $r1 1 ]
    set NAME [ lindex $r1 2 ]
    set ALIAS [ lindex $r1 3 ]
	set TYPE [ lindex $r1 4 ]
	set s1 "$ID1 ,($TYPE),$NAME = $GUID"
	set l1 [ string length $s1 ]
	puts $s1
	LogWrite $s1

	DG_LIST $ID1 $l1

	set ret1 [ DG_GROUPS $ID1 1 ]

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
