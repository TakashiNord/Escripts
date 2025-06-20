
##
## скрипт создает папку out и в ней директории и файлы по каждому параметру. (16000 параметров = 2 час работы)
##   также, создает промежуточную sqlite БД. она не нужна, просто атавизм от предыдущего проекта
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
## 3/ создаем папку по названию обьекта
## 5. в папке формируем файл по каждому из параметров = dt;val;
##    предварительно , убираем из имени параметра - спецсимволы
##
## Вывод в папку out в текущей со скриптом
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

# создаем таблицу-вьюшку ALL_OBJECTS1
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
    set s1 "INSERT INTO _ALL_OBJECTS1 values($s0)"
    LogWrite $s0
    db1 eval "$s1"
  }
  db1 eval {COMMIT}

}


# ===============================================
proc  CreateTable { id_param ps_name param_name tbname nm } {
# ===============================================
  global db1
  global db2

  set tempname $param_name

  regsub -all "<" $tempname "(" tempname
  regsub -all ">" $tempname ")" tempname
  regsub -all "/" $tempname "_" tempname
  regsub -all {\\} $tempname "_" tempname
  regsub -all {:} $tempname "=" tempname
  regsub -all {"} $tempname "'" tempname

  set name_file $nm\\${tempname}($id_param).csv

  set ff [ open $name_file "w+"  ]
  #puts $ff "dt;val;state;"
  puts $ff "-1;${ps_name}-${param_name};"

  set T1 "to_date('2017.09.07 23:59', 'YYYY.MM.DD HH24:MI')"  ; # sysdate
  set T2 95 ; ## 365 95

  set strSQL7 "SELECT count(*) FROM %s where time1970 > to_dt1970(trunc ($T1-$T2))"
  set strSQL9 "SELECT * FROM \
     ( SELECT %s , row_number() over (order by 1) rn FROM %s WHERE time1970 > to_dt1970(trunc ($T1-$T2))  order by time1970 ) \
   WHERE rn > %d and rn <= %d"

  #set columns2 " to_char(from_dt1970 (time1970), 'YYYY.MM.DD HH24:MI'), val, state " ; # select
  set columns2 " time1970, val " ; # select

  #return ;

  set s3 [ format $strSQL7 $tbname ]
  set cnt 0 ; # число записей
  foreach {r3} [ db2 $s3 ] {
    set cnt [lindex $r3 0]
  }
  LogWrite "-- Records=$cnt"
  if {$cnt<=0} { 
    close $ff; 
	catch { file delete -force -- $name_file }
	return 0 ; 
  }

  LogFlush

  set cNum 300000 ;
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
        append s0 "$s1"
        append s0 ";"
      }
      set s1 $s0
      incr cnt_insert ;
      puts $ff "$s1"
    }

  }

  close $ff

  return 0 ;
}


# ===============================================
proc  CreateDir { } {
# ===============================================
  global db1

  set ph [info script]
  if {$ph==""} {
    set ph [ pwd ]
  } else {
    set ph [file dirname $ph ]
  }

  # формируем столбцы, создаем таблицу, копируем данные - последовательно.
  set cnt_table 0 ; # количество таблиц
  db1 eval {select id_param, ps_name, param_name, retfname from _ALL_OBJECTS1} {
    incr cnt_table
    set nm "$ph\\out\\$ps_name"
    if {![file exists $nm]} {
       file mkdir $nm
    }
    LogWrite "-- $retfname  ($cnt_table)"
    CreateTable $id_param $ps_name $param_name $retfname $nm
  }
  return 0 ;
}



# ===============================================
proc  main { } {
# ===============================================
  global db1
  global db2
  global rf

  # avtorization
  set tns "rsdu2"
  set usr "rsduadmin" ; #  admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz


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

  CreateDir

  db1 close

# Закрываем соединение к БД
#  db2 commit
  db2 disconnect

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nend = $t1"
  LogWrite "\n--END=$t1"

  close $rf
  
  ## в случае отладки не удалять
  catch { file delete -force -- $ph }

  return 0 ;
}

  main

