
package require tclodbc

#puts "-- Start --"


proc LogWrite  { s } {
  global rf
  if {![info exists rf]} { return }
  if {$rf==""} { return }
  puts $rf $s
}

proc LogWriteAdd  { rf s } {
  #global rf
  if {![info exists rf]} { return }
  if {$rf==""} { return }
  puts $rf $s
}


proc GetSource { rf fpid level header } {
  global db1
  global Num

  set sql4 "Select ID, ID_SOURCE FROM MEAS_SRC_CHANNEL where ID_OWNLST=$fpid "

  set st [ string repeat " " $level ]

  set ALIAS1 ""
  set str ""
  foreach {r1} [ db1 $sql4 ] {
    set ALIAS1 ""
    set str ""
    set portn 0
    set id [ lindex $r1 0 ]
    set ids [ lindex $r1 1 ]
    set sql44 "Select ID, ALIAS, PORT_NUM FROM MEAS_SOURCE where ID=$ids "
    foreach {r11} [ db1 $sql44 ] {
      set id11 [ lindex $r11 0 ]
      set ALIAS1 [ lindex $r11 1 ]
      set portn  [ format %d [ lindex $r11 2 ] ]
    }
    # Оператор Дорасчет
    # [string compare -nocase $ALIAS1 "Дорасчет" ]==0
    if {$portn==1} {
      set sql45 "Select ID_CHANNEL, FORMULE FROM MEAS_SRC_CHANNEL_CALC where ID_CHANNEL=$id "
      foreach {r12} [ db1 $sql45 ] {
        set id12 [ lindex $r12 0 ]
        set str [ lindex $r12 1 ]
        #set str "${ALIAS1};\"${str}\";${fpid}"
		set str "${ALIAS1};\"${str}\";"
      }
      if {$str==""} {
        ;
        # [string compare -nocase $ALIAS1 "Оператор" ]==0
        #set str "${ALIAS1};0;${fpid}"
		set str "${ALIAS1};0;"
		set str "" ; continue ;
      }
    } else {
        set sql45 "Select ID, ID_SRCTBL, ID_SRCLST FROM MEAS_SRC_CHANNEL_TUNE where ID_CHANNEL=$id "
        set ids  "" ;
        set idsl "" ;
        foreach {r123} [ db1 $sql45 ] {
          set id12 [ lindex $r123 0 ]
          set ids [ lindex $r123 1 ]
          set idsl [ lindex $r123 2 ]
        }
        set str  " $ids  - $idsl "

       if {$ids==""} { set ids 0 }

set sql001 "SELECT DISTINCT id, id_lsttbl,name FROM sys_tree21 WHERE id_lsttbl IN \
(SELECT id FROM sys_tbllst WHERE id_type IN (SELECT id FROM sys_otyp WHERE define_alias like 'LST') \
AND id_node IN \
(SELECT id FROM sys_db_part WHERE id_parent IN (SELECT id FROM sys_db_part WHERE define_alias like 'MODEL_SUBSYST' OR define_alias like 'DA_SUBSYST' ))) \
and id_lsttbl= $ids ";
        set name_lsttbl  "" ;
        foreach {r001} [ db1 $sql001 ] {
          set name_lsttbl [ lindex $r001 2 ]
        }

        # получаем табл
        set sql002 "SELECT UPPER(lst.TABLE_NAME), lst.name FROM sys_tbllst lst WHERE lst.ID=$ids"
        set TABLE_NAME  "" ;
        set name_lsttbl2  "" ;
        foreach {r002} [ db1 $sql002 ] {
          set TABLE_NAME [ lindex $r002 0 ]
          set name_lsttbl2 [ lindex $r002 1 ]
        }
        set str  "${name_lsttbl2}($ids);;$idsl"

        if {$TABLE_NAME!=""} {

         if {[string match -nocase *PHREG_LIST_V* $TABLE_NAME]} {
              set nm1 ""
              set na1 ""
              set nc1 ""
              set sql46 "Select ID,ID_NODE, id_type, NAME,ALIAS FROM phreg_list_v where ID=$idsl "
              foreach {r124} [ db1 $sql46 ] {
                set nm1 [ lindex $r124 3 ]
                set na1 [ lindex $r124 4 ]
              }
              set str  "${str};;${nm1};${na1};${nc1}"
         }
         if {[string match -nocase *ELREG_LIST_V* $TABLE_NAME]} {
              set nm1 ""
              set na1 ""
              set nc1 ""
              set sql46 "Select ID,ID_NODE,id_type,NAME,ALIAS FROM elreg_list_v  where ID=$idsl "
              foreach {r124} [ db1 $sql46 ] {
                set nm1 [ lindex $r124 3 ]
                set na1 [ lindex $r124 4 ]
              }
              set str  "${str};;${nm1};${na1};${nc1}"
         }
         if {[string match -nocase *DA_V_LST* $TABLE_NAME]} {

              set pribor1 ""
              set nm1 ""
              set na1 ""
              set nc1 ""
              set sql46 "Select dp.ID,dp.ID_NODE,dc.NAME,dp.NAME,dp.ALIAS,dd.CVALIF FROM DA_PARAM dp, DA_DEV_DESC dd, DA_CAT dc \
                          where dp.ID=$idsl and dd.ID=dp.ID_POINT and dp.ID_NODE=dc.id"
              foreach {r124} [ db1 $sql46 ] {
                set pribor1 [ lindex $r124 2 ]
                set nm1 [ lindex $r124 3 ]
                set na1 [ lindex $r124 4 ]
                set nc1 [ lindex $r124 5 ]
              }
              set str  "${str};${pribor1};${nm1};${na1};${nc1}"

         }

        }


    }

    set p [ expr $level+1 ]
    #LogWriteAdd $rf " $st !SOURCE= \[ $id \] $ALIAS1 = $str"
    set str2 ";${ALIAS1};${str}"
    set str3 "${header}${str2}"
    LogWriteAdd $rf $str3

  }

  #puts "$fpid"

  return 0
}

proc GetElem { fpid header } {
  global db1
  
  set h $header

  set sql4 "Select ID,ID_PARENT,ID_TYPE,NAME,ALIAS from OBJ_TREE where ID=$fpid"

  foreach {r2} [ db1 $sql4 ] {
    set id [ lindex $r2 0 ]
	set id_par [ lindex $r2 1 ]
    set name [ lindex $r2 3 ]
    
    set str "${name}\\${h}"
	if {$id_par==""} { break ;}
    set h [ GetElem $id_par $str ]
  }

  return $h
}


proc pObj { } {
  global db1
  global rf

  #  RSDUADMIN.ELREG_LIST_V
  set sql4 "Select ID,ID_NODE,ID_TYPE,NAME,ALIAS from RSDUADMIN.ELREG_LIST_V order by ID"

  set n 0
  foreach {r1} [ db1 $sql4 ] {
    set id [ lindex $r1 0 ]
    set node [ lindex $r1 1 ]
    set tp [ lindex $r1 2 ]
    set name [ lindex $r1 3 ]
    
	set str ""
    set header [ GetElem $node $str ]
	#set str "${header};${id};${name}"

    #ascii cp1251 koi8-u unicode
	set s1 "\u0433\u0435\u043d\u0435\u0440\u0430\u0446\u0438\u044f" ; #"*генерация*"
	set s2 $header
	#set s1 [ encoding convertfrom ascii "*генерация*" ]
	#set s2 [ encoding convertfrom cp1251 $header ]
    #set s1 [ encoding convertto cp1251 "*генерация*" ]
    #set s2 [ encoding convertto cp1251 $header ]	
	
	#if {[string match -nocase $s1 $s2 ]==1} { 
	#  puts $header
	  GetSource  $rf $id 1 ";${header};${id};${name}"
	  incr n
	#}
	
	#LogWrite $str
  }

  return $n
}

# ===============================================
proc  main { } {
# ===============================================
  global db1
  global db2
  global own
  global rf
  global Num

  # avtorization
  set tns "rsdu2"
  set usr "rsduadmin" ; # sys "rsduadmin" admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz

  set t1 [ clock format [ clock seconds ] -format "%T" ]

  set t11 [ clock format [ clock seconds ] -format "%Y%m%d_%H%M%S" ]
  
  puts "\nstart = $t1"

# Óñòàíàâëèâàåì ñîåäèíåíèå ê ÁÄ
  database db1 $tns $usr $pwd
#  db1 set autocommit off

  set namefile "obj"

  # ëîã - ôàéë
  set ph [info script]
  set md "a+"
  if {$ph==""} {
     set ph obj_tree_${t11}.log
  } else {
     set p1 [ file dirname $ph ] ; # [file dirname /foo/bar/grill.txt] -> /foo/bar
     set ph [ file join $p1 ${ph} ]_${t11}.log
     set md "w+"
  }

# -------------------------------------------------------------------------------------------------

  set rf [ open $ph $md ]
  #set rf stdout ; # вывод в стандартное устройство

# -------------------------------------------------------------------------------------------------

  set nm [ pObj ]
  
  puts "done . $nm strings."


# ===============================================
# Закрываем соединение к БД
#  db1 commit
  db1 disconnect

  close $rf

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nend = $t1"

  return 0 ;
}

  main

  #puts "-- End --"