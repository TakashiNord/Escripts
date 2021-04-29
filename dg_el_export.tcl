#
# Экспорт таблиц - данных раздела DG
# и связанных с ними таблиц Технологического режима EL(29)
#
# Период = От текущей даты - 7 дней.
#
#



package require tclodbc
package require sqlite3

set tns "rsdu2"
set usr "rsduadmin" ; #  admin  nov_ema
set pwd "passme" ; # passme  qwertyqaz

puts "-- Start --"


# Устанавливаем соединение к БД
 database db2 $tns $usr $pwd
 db2 set autocommit off

 set owner "RSDUADMIN"

# ===============================================
  set ph [info script]

#1.
#CREATE TABLE DG_ARC
#
#  ID_PARAM  NUMBER(11),
#  ID_GINFO  NUMBER(11) CONSTRAINT DG_ARC_ID_GINFO_NN NOT NULL,
#  RETFNAME  VARCHAR2(15 BYTE) CONSTRAINT DG_ARC_RETFNAME_NN NOT NULL
#

#RSDU2DGARH.

  set strSQL1 "SELECT ID_PARAM, ID_GINFO, RETFNAME  FROM DG_ARC ORDER BY ID_PARAM"

  foreach {r1} [ db2 $strSQL1 ] {
    set ID_PARAM1 [ lindex $r1 0 ]
    set ID_GINFO1 [ lindex $r1 1 ]
    set RETFNAME1 [ lindex $r1 2 ]

    set strSQL2 "SELECT count(*)  FROM %s"
    set strSQL2 [ format $strSQL2 $RETFNAME1 ]

    set cnt 0
    foreach {r2} [ db2 $strSQL2 ] {
      set cnt [ lindex $r2 0 ]
    }
    set cnt [ format %d $cnt ]
    puts " $RETFNAME1 = $cnt"

    if {$cnt>0} {
     set ph1 [file rootname $ph]_$RETFNAME1.sql
     set rf [ open $ph1 "w+"  ]
     set strSQL3 "SELECT TIME1970, VAL, STATE  FROM %s WHERE from_dt1970(TIME1970)>(SYSDATE-7) ORDER BY TIME1970 DESC"
     set strSQL3 [ format $strSQL3 $RETFNAME1 ]
     foreach {r3} [ db2 $strSQL3 ] {
        set TIME19701 [ lindex $r3 0 ]
        set VAL1 [ lindex $r3 1 ]
        set STATE1 [ lindex $r3 2 ]

        set sinsert "INSERT INTO ${RETFNAME1} (TIME1970, VAL, STATE) VALUES (${TIME19701},${VAL1},${STATE1}) ; "

        set smerge " MERGE INTO ${RETFNAME1} A USING \
 (SELECT ${TIME19701} as \"TIME1970\", ${VAL1} as \"VAL\", ${STATE1} as \"STATE\" FROM DUAL) B \
ON (A.TIME1970 = B.TIME1970) \
WHEN NOT MATCHED THEN \
INSERT ( TIME1970, VAL, STATE) VALUES ( B.TIME1970, B.VAL, B.STATE) \
WHEN MATCHED THEN \
UPDATE SET A.VAL = B.VAL, A.STATE = B.STATE ; "

        #puts $rf $smerge
        puts $rf $sinsert
     }
     flush $rf
     close $rf
    }
  }


#CREATE TABLE DG_SRC_CHANNEL_TUNE
#(
#  ID          NUMBER(11),
#  ID_CHANNEL  NUMBER(11),
#  ID_SRCTBL   NUMBER(11),
#  ID_SRCLST   NUMBER(11)
#)

#RSDU2ELARH.

  set strSQL1 "SELECT ID, ID_CHANNEL, ID_SRCTBL, ID_SRCLST  FROM DG_SRC_CHANNEL_TUNE ORDER BY ID"

  foreach {r1} [ db2 $strSQL1 ] {
    set ID_SRCTBL1 [ lindex $r1 2 ]
    set ID_SRCLST1 [ lindex $r1 3 ]

    set RETFNAME1 ""
    set strSQL2 "SELECT RETFNAME FROM MEAS_ARC WHERE ID_PARAM=$ID_SRCLST1 AND ID_GTOPT=4 "
    foreach {r2} [ db2 $strSQL2 ] {
      set RETFNAME1 [ lindex $r2 0 ]
    }
    puts " $ID_SRCLST1 -4- RETFNAME = $RETFNAME1 "
    if {$RETFNAME1==""} { continue ; }

    set ph1 [file rootname $ph]_$RETFNAME1.sql
    set rf [ open $ph1 "w+"  ]
    set strSQL3 "SELECT TIME1970, VAL, STATE  FROM %s WHERE from_dt1970(TIME1970)>(SYSDATE-7) ORDER BY TIME1970 DESC"
    set strSQL3 [ format $strSQL3 $RETFNAME1 ]
    foreach {r3} [ db2 $strSQL3 ] {
       set TIME19701 [ lindex $r3 0 ]
       set VAL1 [ lindex $r3 1 ]
       set STATE1 [ lindex $r3 2 ]

       set sinsert "INSERT INTO ${RETFNAME1} (TIME1970, VAL, STATE) VALUES (${TIME19701},${VAL1},${STATE1}) ; "

       set smerge " MERGE INTO ${RETFNAME1} A USING \
 (SELECT ${TIME19701} as \"TIME1970\", ${VAL1} as \"VAL\", ${STATE1} as \"STATE\" FROM DUAL) B \
ON (A.TIME1970 = B.TIME1970) \
WHEN NOT MATCHED THEN \
INSERT ( TIME1970, VAL, STATE) VALUES ( B.TIME1970, B.VAL, B.STATE) \
WHEN MATCHED THEN \
UPDATE SET A.VAL = B.VAL, A.STATE = B.STATE ; "

       #puts $rf $smerge
       puts $rf $sinsert
    }
    flush $rf
    close $rf
  }

# ===============================================
# Закрываем соединение к БД
#  db2 commit
  db2 disconnect

  puts "-- End --"
