
package require tclodbc
package require sqlite3

#
# RSDU2 Oracle to Sqlite
# 2016 - 2023 year
#
#

  # avtorization
  global tns usr pwd
  set tns "rsdu2"
  set usr "rsduadmin" ; # sys "rsduadmin" admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz

  global out_journal out_meas30
  set out_journal "OFF" ; # не выводить журналы
  set out_meas30  "OFF" ; # не выводить meas*

  global schema
  set schema [ list "RSDUADMIN" ]
  #set schema [ list "RSDUADMIN" "RSDU2DAARH" "RSDU2ELARH" "RSDU2PHARH" "RSDU2PSARH" "RSDU2AUARH" "RSDU2CLARH" "RSDU2EAARH" "RSDU2DGARH" "RSDU2EXARH" ]
  #set schema [ list "RSDUADMIN" "RSDU2ELARH" "RSDU2PHARH" "RSDU2PSARH" "RSDU2AUARH" "RSDU2DGARH" "RSDU2EXARH" ]

  global schemav
  set schemav [ list "RSDUADMIN" ]


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

# ===============================================
proc  CreateTable_ALL_OBJECTS { owner } {
# ===============================================
  global db1
  global db2

  LogWrite "-- ALL_OBJECTS $owner"

  set name_t "_ALL_OBJECTS_${owner}"

# создаем таблицу-вьюшку ALL_OBJECTS
  set str "create table if not exists $name_t (\
   OWNER text, \
   OBJECT_NAME  text, \
   SUBOBJECT_NAME  text, \
   OBJECT_ID  text, \
   DATA_OBJECT_ID  text, \
   OBJECT_TYPE  text, \
   CREATED  text, \
   LAST_DDL_TIME  text, \
   TIMESTAMP  text, \
   STATUS  text, \
   TEMPORARY  text, \
   GENERATED  text, \
   SECONDARY   text ) "

  db1 eval $str

  #set strSQL1 "SELECT * FROM all_objects WHERE owner = '%s' AND object_type = 'TABLE'"
  set strSQL1 "SELECT * FROM all_objects WHERE owner = '%s' "

  set s2 [ format $strSQL1 $owner ]
  db1 eval {BEGIN}
  foreach {r1} [ db2 $s2 ] {
    set s0 ""
    set n [llength $r1]
    for  {set i 0} {$i < $n } {incr i} {
      set s1 [lindex $r1 $i]
      set s0 "$s0'$s1'"
      if {$i!=[expr $n-1]} {  set s0 "$s0," }
    }
    set s1 "INSERT INTO $name_t values($s0)"
    LogWrite $s1
    db1 eval "$s1"
  }
  db1 eval {COMMIT}

}

# ===============================================
proc  CreateTable_all_views { owner } {
# ===============================================
  global db1
  global db2

  LogWrite "-- all_views $owner"

  set name_v "_all_views_${owner}"

# создаем таблицу-вьюшку _all_views
  set str "create table if not exists $name_v (\
   OWNER text, \
   VIEW_NAME  text, \
   TEXT_LENGTH  text, \
   TEXT  text ) "

  db1 eval $str

  set strSQL1 "SELECT OWNER,VIEW_NAME,TEXT_LENGTH,TEXT FROM all_views WHERE owner = '%s' "

  set s2 [ format $strSQL1 $owner ]
  db1 eval {BEGIN}
  foreach {r1} [ db2 $s2 ] {
    set s0 ""
    set n [llength $r1]
    for  {set i 0} {$i < $n } {incr i} {
      set s1 [lindex $r1 $i]
      set s1 [ string map {' ''} $s1 ]
      set s0 "$s0'$s1'"
      if {$i!=[expr $n-1]} {  set s0 "$s0," }
    }
    set s1 "INSERT INTO $name_v values($s0)"
    LogWrite $s1
    db1 eval "$s1"
  }
  db1 eval {COMMIT}

}


# ===============================================
proc  CreateTable { tbname owner } {
# ===============================================
  global db1
  global db2
  #global owner

  ##  all_tab_columns   USER_TAB_COLUMNS
  set strSQL55 "SELECT F.column_name, F.data_type, F.data_length, F.data_scale, F.nullable FROM all_tab_columns F WHERE F.TABLE_NAME = '%s'"
  set strSQL5 "SELECT F.column_name, F.data_type, F.data_length, F.data_scale, F.nullable FROM all_tab_columns F WHERE F.TABLE_NAME = '%s' and F.owner='%s'"
  set strSQL6 "SELECT %s FROM %s"
  set strSQL7 "SELECT count(*) FROM %s"
  set strSQL8 "SELECT * FROM ( SELECT %s.* , row_number() over (order by 1) rn FROM %s ) WHERE rn = %d"
  set strSQL9 "SELECT * FROM ( SELECT %s , row_number() over (order by 1) rn FROM %s ) WHERE rn > %d and rn <= %d"
  set strSQL10 "SELECT * FROM ( SELECT %s.* , row_number() over (order by 1) rn FROM %s ) WHERE rn > %d and rn <= %d"

  # формируем столбцы, создаем таблицу, копируем данные - последовательно.
  set columns1 "" ; # create
  set columns2 "" ; # select
  set columns3 "" ; # insert
  set s5 [ format $strSQL5 $tbname $owner ]
  #LogWrite $s5
  foreach {r2} [ db2 $s5 ] {
    set raw  0 ; # convert raw format
    set column [ lindex $r2 0 ]
    set data_type [ lindex $r2 1 ]
    set data_length [ lindex $r2 2 ]
    set data_scale [ lindex $r2 3 ]
    set nullable [ lindex $r2 4 ]
    append columns1 ", $column"
    # nvarchar(n)  text
    if {$data_type=="VARCHAR2"} { append columns1 " nvarchar($data_length)" ; }
    # decimal  integer  real number
    if {$data_type=="NUMBER"} {
      switch -- $data_scale {
        "0" { append columns1 " decimal" ; }
        ""  { append columns1 " decimal" ; }
        default {
          append columns1 " real" ;
         }
      }
    }
    # date
    if {$data_type=="DATE"} { append columns1 " text" ; }
    # blob
    if {$data_type=="RAW"} { append columns1 " text" ; set raw 1 ; }

    if {$data_type=="CLOB"} { append columns1 " text" ; set raw 1 ; }

    if {$nullable=="N"} { append columns1 " NOT NULL" ; }
    if {$raw==1} {
       append columns2 ", cast(${tbname}.$column  as varchar(256))"
    } else {
       append columns2 ", ${tbname}.${column}"
    }
    append columns3 ", $column"
  }
  set columns1 [ string trimleft $columns1 "," ]
  set columns1 [ string trim $columns1 " " ]
  set s6 [ format "create table if not exists %s (%s)" $tbname $columns1 ]
  LogWrite $s6
  db1 eval $s6
  set columns2 [ string trimleft $columns2 "," ]
  set columns2 [ string trim $columns2 " " ]
  set columns3 [ string trimleft $columns3 "," ]
  set columns3 [ string trim $columns3 " " ]

  #return ;

  set s3 [ format $strSQL7 $tbname ]
  set cnt 0 ; # число записей
  foreach {r3} [ db2 $s3 ] {
    set cnt [lindex $r3 0]
  }
  LogWrite "-- Records=$cnt"
  if {$cnt<=0} { return 0 ; }

  LogFlush


  global out_journal out_meas30
  # не выводить журналы
  if {$out_journal=="OFF"} {
    if {0==[ string compare -nocase -length 2 "j_" $tbname ]} { return 0 ; }
  }

  # не выводить MEAS_SNAPSHOT30
  if {$out_meas30=="OFF"} {
    if {0==[ string compare -nocase "MEAS_SNAPSHOT30" $tbname ]} { return 0 ; }
  }

  #if {0==[ string compare -nocase "MEAS_FUNCTION_TEMPLATE" $tbname ]} { return 0 ; }

  set cNum 500000 ;
  set cnt_insert 0 ; # число записей ВСТАВКИ
  set iCnt 0
  while {$cnt>$iCnt} {
    set s3 [ format $strSQL9 $columns2 $tbname $iCnt [ expr $iCnt+$cNum ] ]
    #LogWrite "$s3"
    set iCnt [ expr $iCnt+$cNum ]
    foreach {r3} [ db2 $s3 ] {
      set s0 ""
      set n [ expr [llength $r3] -1 ]
      for {set i 0} {$i < $n} {incr i} {
        set s1 [lindex $r3 $i]
        if {[string first ' $s1]>=0} {
          regsub -all {[']+} $s1 {''} d
          set s1 $d
        }
        append s0 "\'$s1\'"
        if {$i!=[expr $n-1]} {  append s0 "," }
      }
      set s1 "INSERT INTO $tbname ($columns3) values($s0)"
      #LogWrite $s1
      if {$cnt_insert==0} { db1 eval {BEGIN} ; }
      incr cnt_insert ;
      db1 eval "$s1"
      if {$cnt_insert>=60} { db1 eval {COMMIT} ; set cnt_insert 0 ; }
    }
    if {$cnt_insert!=0} { db1 eval {COMMIT} ; set cnt_insert 0 ; }
  }

  return 0 ;
}


# ===============================================
proc  CreateTables { strSQL owner } {
# ===============================================
  global db2
  global out_journal out_meas30


  # формируем столбцы, создаем таблицу, копируем данные - последовательно.
  set cnt_table 0 ; # количество таблиц
  foreach {r1} [ db2 $strSQL ] {
    incr cnt_table
    set tbname [ lindex $r1 0 ]
    LogWrite "\n-- $tbname  ($cnt_table)"

    set out_flag 1

    # не выводить журналы
    #if {$out_journal=="OFF"} {
    #    if {0==[ string compare -nocase -length 2 "j_" $tbname ]} { set out_flag 0 ; }
    #}

    # не выводить MEAS_SNAPSHOT30
    #if {$out_meas30=="OFF"} {
    #    if {0==[ string compare -nocase "MEAS_SNAPSHOT30" $tbname ]} { set out_flag 0 ; }
    #}

    if {$out_flag==1} {
      catch {
           CreateTable $tbname $owner
      } err
    }

  }

  return 0 ;
}


# ===============================================
proc  main { } {
# ===============================================
  global tns usr pwd
  global db1
  global db2
  global own
  global rf

  set tN [ clock format [ clock seconds ] -format "%Y%m%d_%H%M%S" ]


# лог - файл
  set ph [info script]
  if {$ph==""} {
    set ph ${tns}_sqlite_${tN}.log
  } else {
    set ph [ file rootname $ph ]_${tN}.log
  }
  set rf [ open $ph "w+"  ]


  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nstart = $t1\n"
  LogWrite "--START=$t1\n"


# Устанавливаем соединение к БД  ORACLE
  database db2 $tns $usr $pwd
  db2 set autocommit off


# открываем - создаем бд
  set ph [info script]
  if {$ph==""} {
    set ph ${tns}_sqlite_${tN}.db
  } else {
    set ph [ file rootname ${ph} ]_${tN}.db
  }


  sqlite3 db1 $ph ;# associate the SQLite database with the object
  db1 eval {PRAGMA synchronous=OFF}
  #db1 eval {PRAGMA journal_mode=OFF}


  # ----------------------------- scheme base of objects
  set owner "RSDUADMIN"
  set err1 ""
  #catch {
  #   CreateTable_ALL_OBJECTS $owner
  #} err1
  #puts "CreateTable_ALL_OBJECTS - $err1"
  set err2 ""
  #catch {
  #  CreateTable DBA_SEGMENTS SYS
  #} err2
  #puts "CreateTable DBA_SEGMENTS SYS - $err2"


  # ----------------------------- create tables
  set strSQL01 "select table_name from all_tables where owner = '%s'"
  set strSQL02 "SELECT * FROM ( SELECT table_name , row_number() over (order by table_name) rn FROM all_tables where owner = '%s' ) WHERE rn <= 100"
  set strSQL03 "SELECT * FROM ( SELECT table_name , row_number() over (order by table_name) rn FROM all_tables where owner = '%s' ) WHERE rn > 100 and rn <= 200"


  global schema
  if {0==[info exists schema]} {
    set schema [ list "RSDUADMIN" ]
  }

  if {0==[llength $schema]} {
    set schema [ list "RSDUADMIN" ]
  }

  foreach owner $schema {
    set s1 [ format $strSQL01 $owner ]
    CreateTables $s1 $owner
  }


  set schema_add1 [ list "RSDU5RETRO" ]
  foreach owner $schema_add1 {
    set s1 [ format $strSQL01 $owner ]
    CreateTables $s1 $owner
    ##CreateTables $owner.$s1 $owner
  }


  set schema_add2 [ list "INP" "RSDUJOB" "RSDU_FMON" ]
  foreach owner $schema_add2 {
    set s1 [ format $strSQL01 $owner ]
    CreateTables $s1 $owner
    ##CreateTables "$owner_$s1" $owner
  }


  # ----------------------------- create views as tables
  global schemav
  if {0==[info exists schemav]} {
    set schemav [ list "RSDUADMIN" ]
  }

  if {0==[llength $schemav]} {
    set schemav [ list "RSDUADMIN" ]
  }

  set err3 ""
  catch {
    CreateTable_all_views $schemav
  } err3
  puts "CreateTable_all_views - $err3"
  set strSQLview "select view_name from all_views where owner = '%s'"
  foreach owner $schemav {
    set s1 [ format $strSQLview $owner ]
    CreateTables $s1 $owner
  }


  # ----------------------------- Sqlite
  db1 close

# Закрываем соединение к БД Oracle
#  db2 commit
  db2 disconnect

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nend = $t1"
  LogWrite "\n--END=$t1"

  close $rf

  return 0 ;
}

  main

