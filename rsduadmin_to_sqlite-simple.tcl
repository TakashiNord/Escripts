

package require tclodbc
package require sqlite3

set tns "rsdu2"
set usr "rsduadmin" ; #  admin  nov_ema
set pwd "passme" ; # passme  qwertyqaz

# лог - файл
  set ph [info script]
  if {$ph==""} {
    set ph rsduadmin_sqlite.log
  } else {
    set ph [file rootname $ph ].log
  }

proc LogWrite  { s } {
  global rf
  if {![info exists rf]} { return }
  if {$rf==""} { return }
  puts $rf $s
}

  #set rf [ open $ph "w+"  ]

# Устанавливаем соединение к БД
 database db2 $tns $usr $pwd
 db2 set autocommit off

 set owner "RSDUADMIN"
 set strSQL1 "SELECT * FROM all_objects WHERE owner = '%s' AND object_type = 'TABLE'"
 set strSQL2 "SELECT column_name FROM all_tab_columns WHERE table_name = '%s'"
 set strSQL3 "SELECT * FROM %s"
 set strSQL4 "select table_name from all_tables where owner = '%s'"
 set strSQL5 "SELECT F.column_name, F.data_type, F.data_length, F.data_scale, F.nullable FROM USER_TAB_COLUMNS F WHERE F.TABLE_NAME = '%s'"
 set strSQL6 "SELECT %s FROM %s"
 set strSQL7 "SELECT * FROM ( SELECT table_name , row_number() over (order by table_name) rn FROM all_tables where owner = '%s' ) WHERE rn < 250"
 set strSQL8 "SELECT * FROM ( SELECT table_name , row_number() over (order by table_name) rn FROM all_tables where owner = '%s' ) WHERE rn > 250"

# Устанавливаем РОЛЬ
# по умолчанию = BASE_EXT_CONNECT_OIK CONNECT => SBOR_STAND_READ
  if {$usr!="rsduadmin"} {
    db "SET ROLE SBOR_STAND_READ , BASE_STAND_READ"
    db "select * from session_roles"
  }

# открываем - создаем бд
  sqlite3 db1 "rsduadmin.sqlite" ;# associate the SQLite database with the object

# создаем таблицу-вьюшку ALL_OBJECTS
  set str "create table if not exists ALL_OBJECTS (\
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

  LogWrite "-- ALL_OBJECTS"
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
    set s1 "INSERT INTO ALL_OBJECTS values($s0)"
    LogWrite $s1
    db1 eval "$s1"
  }
  db1 eval {COMMIT}

  db1 eval {PRAGMA synchronous=OFF}
  db1 eval {PRAGMA journal_mode = OFF }

# ===============================================
  # формируем строки, создаем таблицу, копируем данные - последовательно.
  set cnt_table 0 ; # количество таблиц
  set s2 [ format $strSQL7 $owner ]
  foreach {r1} [ db2 $s2 ] {
    incr cnt_table
    set tbname [ lindex $r1 0 ]
    set columns1 "" ; # create
    set columns2 "" ; # select
    set columns3 "" ; # insert
    set s5 [ format $strSQL5 $tbname ]
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
      # decimal  integer  real
      if {$data_type=="NUMBER" && $data_scale=="0"} { append columns1 " decimal" ; }
      if {$data_type=="NUMBER" && $data_scale!="0"} { append columns1 " real" ; }
      # date
      if {$data_type=="date"} { append columns1 " text" ; }
      # blob
      if {$data_type=="RAW"} { append columns1 " text" ; set raw 1 ; }
      if {$nullable=="N"} { append columns1 " NOT NULL" ; }
      if {$raw==1} {
         append columns2 ", utl_raw.cast_to_varchar2($column)"
      } else {
         append columns2 ", $column"
      }
      append columns3 ", $column"
    }
    set columns1 [ string trimleft $columns1 "," ]
    set columns1 [ string trim $columns1 " " ]
    set str "create table if not exists %s (%s)"
    set s6 [ format $str $tbname $columns1 ]
    LogWrite $s6
    db1 eval $s6
    set columns2 [ string trimleft $columns2 "," ]
    set columns2 [ string trim $columns2 " " ]
    LogWrite "-- $tbname"
    set s3 [ format $strSQL6 $columns2 $tbname ]
    set columns3 [ string trimleft $columns3 "," ]
    set columns3 [ string trim $columns3 " " ]
    set cnt 0 ; # число записей
  set r33 [ db2 $s3 ]
    foreach {r3} $r33 {
      set s0 ""
      set n [llength $r3]
      for {set i 0} {$i < $n} {incr i} {
        set s1 [lindex $r3 $i]
        if {[string first ' $s1]>=0} {
          set s1 "_____"
        }
    append s0 "\'$s1\'"
        if {$i!=[expr $n-1]} {  append s0 "," }
      }
      set s1 "INSERT INTO $tbname ($columns3) values($s0)"
      LogWrite $s1
      if {$cnt==0} { db1 eval {BEGIN} ;}
      incr cnt ;
      db1 eval "$s1"
      if {$cnt>=60} { db1 eval {COMMIT} ; set cnt 0 ; }
    }
  #unset r33
    if {$cnt!=0} { db1 eval {COMMIT} ; set cnt 0 ; }
    #flush $rf
  }


 # ===============================================
  # формируем строки, создаем таблицу, копируем данные - последовательно.
  set cnt_table 0 ; # количество таблиц
  set s2 [ format $strSQL8 $owner ]
  foreach {r1} [ db2 $s2 ] {
    incr cnt_table
    set tbname [ lindex $r1 0 ]
    set columns1 "" ; # create
    set columns2 "" ; # select
    set columns3 "" ; # insert
    set s5 [ format $strSQL5 $tbname ]
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
      # decimal  integer  real
      if {$data_type=="NUMBER" && $data_scale=="0"} { append columns1 " decimal" ; }
      if {$data_type=="NUMBER" && $data_scale!="0"} { append columns1 " real" ; }
      # date
      if {$data_type=="date"} { append columns1 " text" ; }
      # blob
      if {$data_type=="RAW"} { append columns1 " text" ; set raw 1 ; }
      if {$nullable=="N"} { append columns1 " NOT NULL" ; }
      if {$raw==1} {
         append columns2 ", utl_raw.cast_to_varchar2($column)"
      } else {
         append columns2 ", $column"
      }
      append columns3 ", $column"
    }
    set columns1 [ string trimleft $columns1 "," ]
    set columns1 [ string trim $columns1 " " ]
    set str "create table if not exists %s (%s)"
    set s6 [ format $str $tbname $columns1 ]
    LogWrite $s6
    db1 eval $s6
    set columns2 [ string trimleft $columns2 "," ]
    set columns2 [ string trim $columns2 " " ]
    LogWrite "-- $tbname"
    set s3 [ format $strSQL6 $columns2 $tbname ]
    set columns3 [ string trimleft $columns3 "," ]
    set columns3 [ string trim $columns3 " " ]
    set cnt 0 ; # число записей
  set r33 [ db2 $s3 ]
    foreach {r3} $r33 {
      set s0 ""
      set n [llength $r3]
      for {set i 0} {$i < $n} {incr i} {
        set s1 [lindex $r3 $i]
        if {[string first ' $s1]>=0} {
          set s1 "_____"
        }
    append s0 "\'$s1\'"
        if {$i!=[expr $n-1]} {  append s0 "," }
      }
      set s1 "INSERT INTO $tbname ($columns3) values($s0)"
      LogWrite $s1
      if {$cnt==0} { db1 eval {BEGIN} ;}
      incr cnt ;
      db1 eval "$s1"
      if {$cnt>=60} { db1 eval {COMMIT} ; set cnt 0 ; }
    }
  #unset r33
    if {$cnt!=0} { db1 eval {COMMIT} ; set cnt 0 ; }
    #flush $rf
  }


# ===============================================
  #db1 eval {VACUUM} ;
  db1 close

# Закрываем соединение к БД
#  db2 commit
  db2 disconnect

  #close $rf

##