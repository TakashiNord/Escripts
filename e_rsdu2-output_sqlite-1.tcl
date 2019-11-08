
##
## скрипт создает sqlite БД. Очень долгая работа!! (1000 таблиц- 2 дня работы)
##
## 1/ открываем Oracle
## 2/ создаем БД sqlite. открываем
##   создаем таблицы:
##       _ALL_OBJECTS1 (id_param decimal, ps_name  text, param_name  text, retfname  text)
## заполняем
##           select a.id_param, t.ast_node_name as ps_name, l.alias param_name,  a.retfname
##               from rpt_obj_substation_mv t
##               join elreg_list_v l on l.id = t.id
##               join meas_arc a on a.id_param=l.id
##               where a.id_ginfo=2
##             order by ps_name
##
##      _ALL_OBJECTS2 (id decimal, ps_name  text, cnt  decimal)
## заполняем
##        select distinct  ps_name, count(ps_name ) as cnt from  _ALL_OBJECTS1 group by ps_name
##
## создаем таблицы по шаблону (по числу обьектов)
##    "create table if not exists T%d (dt text)"
##    и для каждой таблицы создаем необходимое количество колонок = количеству параметров.
##     "select param_name, retfname from  _ALL_OBJECTS1 where ps_name='%s'" $ps_name
##     "ALTER TABLE T$cnt_table ADD COLUMN $retfname TEXT Default NULL"
##
## Далее, обходим все таблицы и заполняем данными из таблицы Oracle
##
##




package require tclodbc
package require sqlite3


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
proc  CreateTable_ALL_OBJECTS { } {
# ===============================================
  global db1
  global db2

  LogWrite "-- ALL_OBJECTS1"

# создаем таблицу-вьюшку ALL_OBJECTS
  set str "create table if not exists _ALL_OBJECTS1 (\
   id_param decimal, \
   ps_name  text, \
   param_name  text, \
   retfname  text) "

  db1 eval $str

  set strSQL1 "select a.id_param, t.ast_node_name as ps_name, l.alias param_name,  a.retfname \
       from rpt_obj_substation_mv t \
       join elreg_list_v l on l.id = t.id \
       join meas_arc a on a.id_param=l.id \
       where a.id_ginfo=2 \
     order by ps_name"

  set sum 0
  set s2 [ format $strSQL1 ]
  db1 eval {BEGIN}
  foreach {r1} [ db2 $s2 ] {
    set s0 ""
    set n [llength $r1]
    for  {set i 0} {$i < $n } {incr i} {
      set s1 [lindex $r1 $i]
      set s0 "$s0'$s1'"
      if {$i!=[expr $n-1]} {  set s0 "$s0," }
    }
    incr sum
    LogWrite $s0
    set s1 "INSERT INTO _ALL_OBJECTS1 values($s0)"
    db1 eval "$s1"
  }
  db1 eval {COMMIT}

  LogWrite "\n-- ALL=$sum\n"

  LogWrite "\n-- ALL_OBJECTS2\n"

# создаем таблицу-object ALL_OBJECTS2
  set str "create table if not exists _ALL_OBJECTS2 (\
   id decimal, \
   ps_name  text, \
   cnt  decimal)"

  db1 eval $str

# создаем таблицы-обьекты и добавляем колонки
# создаем таблицу-object N --    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  set strN "create table if not exists T%d (\
   dt text)"

  set cnt_table 0 ; # количество таблиц
  db1 eval {select distinct  ps_name, count(ps_name ) as cnt from  _ALL_OBJECTS1 group by ps_name} {
    incr cnt_table
    db1 eval {INSERT INTO _ALL_OBJECTS2 VALUES($cnt_table,$ps_name,$cnt)}
    set st [ format $strN $cnt_table ]
    db1 eval $st
    set st "INSERT INTO T$cnt_table VALUES(-1)"
    db1 eval $st
    set st [ format "select param_name, retfname from  _ALL_OBJECTS1 where ps_name='%s'" $ps_name ]
    db1 eval $st {
      set st "ALTER TABLE T$cnt_table ADD COLUMN $retfname TEXT Default NULL"
      db1 eval $st
      set st [ format "UPDATE T%d SET  %s='%s' WHERE dt = -1" $cnt_table $retfname $param_name ]
      db1 eval $st
    }
  }

  LogWrite "-- Tsum=$cnt_table"
  LogFlush

  # Период начала отбора и количество дней
  ##select to_char(sysdate, 'YYYY.MM.DD HH24:MI') from dual
  ##select to_date('2017.08.22 23:59', 'YYYY.MM.DD HH24:MI')   sysdate  from dual
  set T1 "to_date('2017.08.20 23:59', 'YYYY.MM.DD HH24:MI')"    ; #
  set T2 365 ; #

  set str "select _ALL_OBJECTS2.id as id, _ALL_OBJECTS2.ps_name as ps_name, _ALL_OBJECTS1.retfname  as retfname \
from _ALL_OBJECTS1, _ALL_OBJECTS2 \
where _ALL_OBJECTS1.ps_name=_ALL_OBJECTS2.ps_name \
order by _ALL_OBJECTS2.id asc"
  set prev_table 0 ; # количество param
  set cnt_param 0 ; # количество param

  db1 eval $str {

    incr cnt_param

    set s3 "SELECT count(*) FROM $retfname where time1970 > to_dt1970(trunc ($T1-$T2))"
    set cnt 0 ; # число записей
    foreach {r3} [ db2 $s3 ] {
      set cnt [lindex $r3 0]
    }
    LogWrite "--( $cnt_param , T$id ) $retfname ( Records=$cnt )"
    LogFlush

    if {$cnt>0} {

      # эта конструкция необходима для Begin-Commit блоками. Блок=1 таблица Т
      if {$prev_table!=$id} {
        if {$prev_table>0} { catch { db1 eval {COMMIT} ; } }
        set prev_table $id
        db1 eval {BEGIN} ;
      }

      # выполняем commit через каждые N параметров
      if {0==[expr $cnt_param % 50]} {
        catch { db1 eval {COMMIT} ; }
        db1 eval {BEGIN} ;
      }

      set strSQL1 "select time1970, val, state from %s where time1970 > to_dt1970(trunc ($T1-$T2)) order by time1970"
      set s3 [ format $strSQL1 $retfname ]
      foreach {r3} [ db2 $s3 ] {
        set dt [lindex $r3 0 ]
        set vl [lindex $r3 1 ]
        set st [ format "SELECT 1 FROM T%d WHERE dt='%s'" $id $dt ]
        if {[db1 exists $st]} {
         # Processing if exists
          set st [ format "UPDATE T%d SET  %s='%s' WHERE dt='%s'" $id $retfname $vl $dt ]
          db1 eval $st
        } else {
         # Processing if does not exist
          set st [ format "INSERT INTO T%d (dt, %s)  values('%s', '%s')" $id $retfname $dt $vl ]
          db1 eval $st
        }
      }

    }

  }

  catch {db1 eval {COMMIT} ;}

}


# ===============================================
proc  main { } {
# ===============================================
  global db1
  global db2
  global owner
  global rf

  # avtorization
  set tns "rsdu2"
  set usr "rsduadmin" ; #  admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz

  # scheme
  set owner "RSDUADMIN"

# лог - файл
  set ph [info script]
  set ph [file rootname $ph ].log

  set rf [ open $ph "w+"  ]

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nstart = $t1\n"
  LogWrite "--START=$t1\n"

# Устанавливаем соединение к БД
  database db2 $tns $usr $pwd
  db2 set autocommit off

# открываем - создаем бд
  set ph [info script]
  set ph [file rootname $ph ].db

  sqlite3 db1 $ph ;# associate the SQLite database with the object

  db1 eval {PRAGMA synchronous=OFF}
  db1 eval {PRAGMA journal_mode=OFF}

  CreateTable_ALL_OBJECTS

  db1 close

# Закрываем соединение к БД
#  db2 commit
  db2 disconnect

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nend = $t1"
  LogWrite "\n--END=$t1"

  close $rf

  return 0 ;
}

  main

