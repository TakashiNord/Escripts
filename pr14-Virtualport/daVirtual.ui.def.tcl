# interface generated by
#
# Подключаем 2-а пакета: для работы с деревом + для подключения к БД через ODBC
package require tclodbc

#=============================================
proc da_dev_virtual3 { tns usr pwd fsql} {
#=============================================
# глобальный список, куда пишем все результаты
# --

# Устанавливаем соединение к БД
  database db $tns $usr $pwd
#db set autocommit off

# Устанавливаем РОЛЬ
# по умолчанию = BASE_EXT_CONNECT_OIK CONNECT => SBOR_STAND_READ = (SELECT = da_dev_desc )  BASE_STAND_READ
  if {$usr!="rsduadmin"} {
    db "SET ROLE SBOR_STAND_READ , BASE_STAND_READ"
    db "select * from session_roles"
  }

  
  
# Шаг 3. DA_SOURCE - Получаем id всех необходимых каналов .
  #аналоговые
    #
	set id_chan_anal_def 0 ; # канал в списке - =основной,'по-умолчанию' .
    set id_channel_anal [list 18 20 ] ; set id_chan_anal_priority [list 0 0 ] ;
  #бул
    set id_chan_bool_def 0 ; # канал в списке - =основной,'по-умолчанию' .
    set id_channel_bool [list 19 21 ] ; set id_chan_bool_priority [list 0 0 ] ;
  #
# Шаг 5. DA_SLAVE - Получаем id_node виртуального канала
  set id_node 3124 ;
# Шаг 6. DA_PARAM - Получаем id всех элементов привязанных к виртуальному каналу
  set str2 "select id, name from da_param where id_node=%ld" ;

  set str2 "select dp.id , dp.name, dd.id_proto_point , dd.id_dev , dd.id_parent ,  dd.cvalif , dd.id_type, sys_gtyp.define_alias \
from da_param dp, da_dev_desc dd, sys_dtyp , sys_gtyp \
where dp.id_node=%ld and dp.id_point=dd.id  \
      and sys_dtyp.id=dd.id_type and sys_dtyp.id_gtype=sys_gtyp.id \
order by sys_gtyp.define_alias"

  set res2 [ format $str2 $id_node ]

# Шаг 7. DA_SRC_CHANNEL - устанавливаем  соответствие Id(параметр)=id(канал)+устанавливаем приоритет 0
  #set strSql71 "insert into DA_SRC_CHANNEL (id, id_ownlst, id_source, alias, priority) values(%ld, %ld, %ld, '%s', %ld) ;"
   set strSql71 "update DA_SRC_CHANNEL SET priority=%ld WHERE id=%ld ;"
# Шаг 7. DA_VAL - устанавливаем источник по-умолчанию  Id(параметр)=id(канал)
  #set strSql72 "insert into DA_VAL (id_param,ID_CUR_CHANNEL_SRC) values(%ld,DECODE(%ld, 0, NULL, %ld)) ;"
  set strSql72 "update DA_VAL SET ID_CUR_CHANNEL_SRC=%ld WHERE id_param=%ld ;"
# Шаг 7. DA_ARC - устанавливаем запись архива (если нужно)
  #set strSql73 "insert into DA_ARC (id_param,ID_GTOPT,RETFNAME,ID_GINFO) values(%ld,%ld,'%s',%ld) ;" 
  set strSql73 "update DA_ARC SET ID_GTOPT=%ld , RETFNAME=%s , ID_GINFO=%ld  WHERE id_param=%ld ;"
# Шаг 7. DA_SRC_CHANNEL_TUNE - связываем канал с таблицей источником
  #set strSql74 "insert into DA_SRC_CHANNEL_TUNE (id, ID_CHANNEL,id_srctbl,id_srclst) VALUES(%ld,%ld,%ld,%ld) ;"
  set strSql74 "insert into DA_SRC_CHANNEL_TUNE (id, ID_CHANNEL,id_srctbl,id_srclst) VALUES(%ld,%ld,%ld,%ld) ;"


  
# =================================
# Основной алгоритм

  set t1 [ clock format [ clock seconds ] -format "_%Y%m%d-%H%M%S" ]
  set ext [ file extension $fsql ]
  set namefile1 [ file rootname $fsql ]
  set namefile $namefile1$t1$ext

  set df [ open $namefile "w+"] ;

  set cnt 0 ; # число выводимых элементов, для контроля

  set id_channel [ ] ; # список для каналов
  set id_chan_priority [ ] ; # список для приоритетов

  set y2 [ db $res2 ]
  foreach {y} $y2 {
	set id_ownlst [lindex $y 0] ;
	set nm [lindex $y 1]

	set cnt [ expr $cnt + 1 ]
	puts $df "--  ----$cnt" ;

	set comment "";

	# - проверяем - существуют ли для элемента каналы
	set num 0 ;
	foreach {yt} [ db "select count(*) from DA_SRC_CHANNEL where id_ownlst=$id_ownlst" ] {
	  set num [ lindex $yt 0 ]
	}
	if {$num<=0} {
	  continue ; # элемента нет
	}
	
	set comment "" ;

    set s1 [ format "%s  '%s'  %s  %s  %s" $id_ownlst $nm [lindex $y 3] [lindex $y 5] [lindex $y 7] ]
    puts $df "-- ----$s1" ;

	# выбираем список каналов? взависимости от типа параметра
	set dalias [lindex $y 7 ] ;
    switch $dalias {
        "GLOBAL_TYPE_ANALOG" -
        "GLOBAL_TYPE_DIGIT" -
        "GLOBAL_TYPE_DANALOG" -
        "GLOBAL_TYPE_DDIGIT" -
        "GLOBAL_TYPE_COMMAND" {
          set id_channel $id_channel_anal ; 
  	      set id_chan_def $id_chan_anal_def ;
	      set id_chan_priority  $id_chan_anal_priority ; 		  
        }
        default {  	
		  set id_chan_def $id_chan_bool_def ;
	      set id_channel $id_channel_bool ;
	      set id_chan_priority  $id_chan_bool_priority ;  
	    }
    }	
	
	foreach {yt} [ db "select * from DA_SRC_CHANNEL where id_ownlst=$id_ownlst " ] {
	    set tid [lindex $yt 0] ;
		set tid_ownlst [lindex $yt 1] ;
		set tid_source [lindex $yt 2] ;
		set talias [lindex $yt 3] ;
		set tpriority [lindex $yt 4] ;
		
		set _ch [ lsearch $id_channel $tid_source ]
		# установка Приоритета
		if {$_ch>=0} { 
		  set value [ lindex $id_chan_priority $_ch ]
		  if {$tpriority!=$value} {
		     set s1 [ format $strSql71 $value $tid ]
		     puts $df "$comment $comment$s1" ;
		  }
		}

	}

	puts $df "--" ;

  }
  
  puts $df "--commit;" ;

  flush $df ; close $df  ;
# =================================

 # Закрываем соединение к БД
  db disconnect ;

  return 0 ;
}


 global   tcl_platform
#============================ задаем константы
  set tns "rsdu2"
  set usr "rsduadmin" ; #  admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz
  set nameFile "da_virtual_def.sql" ; # имя файла для сохранения результата
#=============================================

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nstart = $t1\n"

  set ls {} ; #[ list ]

  set ret [ da_dev_virtual3 $tns $usr $pwd $nameFile ]

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nend = $t1"


