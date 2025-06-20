#
# Экспорт таблиц
#
package require tclodbc
package require sqlite3

# ================================================================

# WHERE  WHERE ID_GINFO=100
set whr "WHERE ID_GINFO=100"

# TIME
set dt1 "from_dt1970(TIME1970)>(SYSDATE-20)"
set dt2 "from_dt1970(TIME1970)<(SYSDATE-11)"

set dt1 "from_dt1970(TIME1970)>to_date('21.04.2021','dd-mm-yyyy')"
set dt2 "from_dt1970(TIME1970)<to_date('30.04.2021','dd-mm-yyyy')"

# TO
set tns "rsdu2"
set usr "rsduadmin" ; #  admin  nov_ema
set pwd "passme" ; # passme  qwertyqaz

# FROM
set tns10 "rsdu10"
set usr10 "rsduadmin" ; #  admin  nov_ema
set pwd10 "passme" ; # passme  qwertyqaz

# ================================================================

# Устанавливаем соединение к БД
 database db2 $tns $usr $pwd
 db2 set autocommit off

# Устанавливаем соединение к БД
 database db10 $tns10 $usr10 $pwd10
 db10 set autocommit off

 puts "-- Start --"

 set owner "RSDUADMIN"

# ===============================================
  set ph [info script]
  set phlog [file rootname $ph]_working.log
  set rflog [ open $phlog "w+"  ]

  set cp 0

  set strSQL1 "SELECT ID_PARAM, ID_GINFO, RETFNAME FROM DG_ARC $whr ORDER BY ID_PARAM"

  foreach {r1} [ db10 $strSQL1 ] {
    set ID_PARAM1 [ lindex $r1 0 ]
    set ID_GINFO1 [ lindex $r1 1 ]
    set RETFNAME1 [ lindex $r1 2 ]

    #if {$ID_GINFO1==6 } { continue ; }
    #if {$ID_GINFO1==28 } { continue ; }
    #if {$ID_GINFO1==1 } { continue ; }
    #if {$ID_GINFO1==5 } { continue ; }

    set strSQL2 "SELECT count(*)  FROM %s"
    set strSQL2 [ format $strSQL2 $RETFNAME1 ]

    set cnt 0
    foreach {r2} [ db10 $strSQL2 ] {
      set cnt [ lindex $r2 0 ]
    }
    set cnt [ format %d $cnt ]
    puts " $RETFNAME1 = $cnt"

    #if {$ID_PARAM1!="6302841" } { continue ; }
    #break ;

    if {$cnt>0} {

        puts $rflog " $RETFNAME1 = $cnt"

        #set ph1 [file rootname $ph]_$RETFNAME1.sql
        #set rf [ open $ph1 "w+"  ]
        set strSQL3 "SELECT TIME1970, VAL, STATE  FROM %s WHERE $dt1 and $dt2 ORDER BY TIME1970 DESC"
        set strSQL3 [ format $strSQL3 $RETFNAME1 ]
        set cntsql 0
        foreach {r3} [ db10 $strSQL3 ] {
            set TIME19701 [ lindex $r3 0 ]
            set VAL1 [ lindex $r3 1 ]
            set STATE1 [ lindex $r3 2 ]

            incr cntsql

            set sinsert "INSERT INTO ${RETFNAME1} (TIME1970, VAL, STATE) VALUES (${TIME19701},${VAL1},${STATE1}) ; "

            set smerge " MERGE INTO ${RETFNAME1} A USING \
 (SELECT ${TIME19701} as \"TIME1970\", ${VAL1} as \"VAL\", ${STATE1} as \"STATE\" FROM DUAL) B \
ON (A.TIME1970 = B.TIME1970) \
WHEN NOT MATCHED THEN \
INSERT ( TIME1970, VAL, STATE) VALUES ( B.TIME1970, B.VAL, B.STATE) \
WHEN MATCHED THEN \
 UPDATE SET A.VAL = B.VAL, A.STATE = B.STATE ; "

            db2 $smerge

            #puts $rf $smerge
            #puts $rf $sinsert
        }
        #flush $rf
        #close $rf

        db2 commit

        incr cp
        puts $rflog " $RETFNAME1 = $cp = $cntsql"
        flush $rflog

    }
  }

  puts "count = $cp"

  close $rflog

# ===============================================
# Закрываем соединение к БД
#  db2 commit

  db10 disconnect

  db2 disconnect

  puts "-- End --"
