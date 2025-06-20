#
# Подключаем 2-а пакета: для работы с деревом + для подключения к БД через ODBC
package require tclodbc

  global tns usr pwd
  global db
  global rf

  set tns "rsdu2" ; #"rsdu2"  "RSDU_ATEC" "Postrsdu5" "poli24"
  set usr "rsduadmin" ; #  admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz

#=============================================
proc LogWrite  { s } {
#=============================================
  global rf
  if {![info exists rf]} { return }
  if {$rf==""} { return }
  puts $rf $s
}
#=============================================
proc LogFlush  { } {
#=============================================
  global rf
  if {![info exists rf]} { return }
  if {$rf==""} { return }
  flush $rf
}



# #21	22	'Parameter1'	'Parameter1'	'select val, date, status from dual'	0	0	2	0		0		
#CREATE TABLE RSDUADMIN.DBE_ACTION
#(
#  ID                    NUMBER(11),
#  ID_JOB                NUMBER(11) CONSTRAINT DBE_ACTION_ID_JOB_NN NOT NULL,
#  NAME                  VARCHAR2(255 CHAR) CONSTRAINT DBE_ACTION_NAME_NN NOT NULL,
#  ALIAS                 VARCHAR2(255 CHAR) CONSTRAINT DBE_ACTION_ALIAS_NN NOT NULL,
#  SQL_TEXT              VARCHAR2(4000 CHAR) CONSTRAINT DBE_ACTION_SQL_TEXT_NN NOT NULL,
#  REQUEST_TIME_OFFSET   NUMBER(11) CONSTRAINT DBE_ACTION_REQUEST_OFFSET_NN NOT NULL,
#  RESPONSE_TIME_OFFSET  NUMBER(11) CONSTRAINT DBE_ACTION_RESPONSE_OFFSET_NN NOT NULL,
#  ID_DTFIELD_TYPE       NUMBER(11) CONSTRAINT DBE_ACTION_ID_DTFIELD_TYPE_NN NOT NULL,
#  ENABLE_ROW_HANDLER    NUMBER(1) CONSTRAINT DBE_ACTION_ROW_HANDLER_NN NOT NULL,
#  ROW_HANDLER_TEXT      VARCHAR2(4000 CHAR),
#  ENABLE_TABLE_HANDLER  NUMBER(1) CONSTRAINT DBE_ACTION_TABLE_HANDLER_NN NOT NULL,
#  TABLE_HANDLER_TEXT    VARCHAR2(4000 CHAR),
#  ID_FILEWAV            NUMBER(11)              DEFAULT NULL
#)
# UPDATE DBE_ACTION SET SQL_TEXT='--', REQUEST_TIME_OFFSET=0, RESPONSE_TIME_OFFSET=0, ID_DTFIELD_TYPE=2 WHERE ID = ???
#

#=============================================
proc dbe_1 { } {
#=============================================
  global db

  set cntOBJ 0

  set str1 "SELECT ID, SQL_TEXT, REQUEST_TIME_OFFSET, RESPONSE_TIME_OFFSET, ID_DTFIELD_TYPE FROM DBE_ACTION WHERE ID_JOB=323 ORDER BY ID"
  foreach {xx} [ db $str1 ] {
    set ID [ lindex $xx 0 ]
	set SQL_TEXT [ lindex $xx 1 ]
	set REQUEST_TIME_OFFSET [ lindex $xx 2 ]
	set RESPONSE_TIME_OFFSET [ lindex $xx 3]
	set ID_DTFIELD_TYPE [ lindex $xx 4 ]

    set s3 "UPDATE DBE_ACTION SET SQL_TEXT='${SQL_TEXT}', REQUEST_TIME_OFFSET=$REQUEST_TIME_OFFSET, RESPONSE_TIME_OFFSET=$RESPONSE_TIME_OFFSET, ID_DTFIELD_TYPE=$ID_DTFIELD_TYPE WHERE ID = $ID ;"
    # stage 1
    LogWrite "$s3"
  }

  LogWrite "-- -- COMMIT ;"

  return 0 ;
}


#=============================================
proc dbe_2 { } {
#=============================================
  global db

  set cntOBJ 0

  set str1 "SELECT ID, SQL_TEXT, REQUEST_TIME_OFFSET, RESPONSE_TIME_OFFSET, ID_DTFIELD_TYPE FROM DBE_ACTION WHERE ID_JOB=323 ORDER BY ID"
  foreach {xx} [ db $str1 ] {
    set ID [ lindex $xx 0 ]
	set SQL_TEXT [ lindex $xx 1 ]
	set REQUEST_TIME_OFFSET 25200
	set RESPONSE_TIME_OFFSET -25200
	set ID_DTFIELD_TYPE 1

    set s3 "UPDATE DBE_ACTION SET SQL_TEXT='${SQL_TEXT}', REQUEST_TIME_OFFSET=$REQUEST_TIME_OFFSET, RESPONSE_TIME_OFFSET=$RESPONSE_TIME_OFFSET, ID_DTFIELD_TYPE=$ID_DTFIELD_TYPE WHERE ID = $ID ;"
    # stage 2
    LogWrite "$s3"
  }

  LogWrite "-- -- COMMIT ;"

  return 0 ;
}


#=============================================
proc main { } {
#=============================================
  global tns usr pwd
  global db
  global rf

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\n----start = $t1\n Open log file"

  set tN [ clock format [ clock seconds ] -format "%Y%m%d_%H%M%S" ]
# лог - файл
  set ph [info script]
  if {$ph==""} {
    set ph ${tns}_pq_${tN}.log
  } else {
    set ph [ file rootname $ph ]_${tN}.log
  }
  set rf [ open $ph "w+"  ]

  LogWrite "--START=$t1\n"

# Устанавливаем соединение к БД
  database db $tns $usr $pwd
  #db set autocommit off

  dbe_1
  #

# Закрываем соединение к БД
  #db commit
  db disconnect

  LogWrite "\n--END=$t1"
  LogFlush

  close $rf

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\n----end = $t1\n Save file."

  return
}

main

