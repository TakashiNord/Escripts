#!/usr/bin/env tclsh


package require tclodbc

proc wr { f r } {
  #puts $f "--------------------------------------"
  foreach r1 $r {
	puts $f $r1
  }
  puts $f "--------------------------------------\n"
  flush $f
}


set tns "rsdu2"
set usr "rsduadmin" ; #  admin  nov_ema
set pwd "passme" ; # passme  qwertyqaz
  
# Устанавливаем соединение к БД
 database db $tns $usr $pwd
 #db set autocommit off

set fr [ open "oracle.txt" "w+"]

#puts $fr "Версия=" 
#set str1 "select * from v$version;" ; 
#wr  $fr [ db $str1 ]

puts -nonewline $fr "Time =" 
set str1 "select sysdate  as \"Current DateTime\", dbtimezone from dual;" ; 
wr  $fr [ db $str1 ]

catch {
puts -nonewline $fr "Time (emcor) = " 
set str1 "select sysdate  as \"Current DateTime\", dbtimezone from DUAL@emcor;" ; 
wr  $fr [ db $str1 ]
}

puts $fr "instance=" 
set str1 "select host_name, instance_name, startup_time, status, version, archiver, logins from gv\$instance" ; 
wr  $fr [ db $str1 ]

puts -nonewline $fr "Кол-во параметров электрического режима = " 
set str1 "select count (*) from elreg_list_v" ; 
wr  $fr [ db $str1 ]

puts -nonewline $fr "Кол-во прочих параметров режима = " 
set str1 "select count (*) from phreg_list_v" ; 
wr  $fr [ db $str1 ]

puts -nonewline $fr "Кол-во  параметров коммутационных аппаратов = "   
set str1 "select count (*) from pswt_list_v" ; 
wr  $fr [ db $str1 ]

puts -nonewline $fr "Кол-во  параметров  устройств  защиты = " 
set str1 "select count (*) from auto_list_v" ; 
wr  $fr [ db $str1 ]

puts $fr "Размер табличных пространств (MB) ="
set str1 "SELECT \
       t.tablespace_name, \
       file_name,  \
       autoextensible \"AutoExtend\",\ 
       bytes /1024/1024 \"Current Size, Mb\",\ 
       t.increment_by* d.block_size /1024/1024 \"Increment, Mb\",\
       maxbytes /1024/1024 \"Max Size, Mb\"\
  FROM Dba_Data_Files t, dba_tablespaces d \
 WHERE d.tablespace_name =  t.tablespace_name " 
wr  $fr [ db $str1 ]


puts $fr "Обновления = "
set str1 "SELECT id, dt1970, define_alias, state FROM RSDU_UPDATE ORDER BY define_alias Desc" ; 
wr  $fr [ db $str1 ]

puts $fr "Список процедур = "
set str1 "select DBA_OBJECTS.OBJECT_NAME, DBA_OBJECTS.LAST_DDL_TIME, DBA_OBJECTS.STATUS , USER_PROCEDURES.PROCEDURE_NAME \
  from dba_objects , USER_PROCEDURES \
  where DBA_OBJECTS.object_type in ('PROCEDURE','FUNCTION','PACKAGE','PACKAGE BODY') \
  and USER_PROCEDURES.OBJECT_ID=DBA_OBJECTS.OBJECT_ID \
  order by DBA_OBJECTS.OBJECT_NAME " ; 
wr  $fr [ db $str1 ]
 
close $fr 

# Закрываем соединение к БД
#  db commit
  db disconnect

