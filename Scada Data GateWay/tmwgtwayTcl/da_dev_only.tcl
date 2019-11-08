
# Подключаем 2-а пакета: для работы с деревом + для подключения к БД через ODBC
package require struct::tree
package require tclodbc


#=============================================
#in:
#  tns        - tns name
#  usr        - login
#  pwd        - password
#  crn        - формирование названия элемента { 0 - обычные имена как в БД, иное - шаблон ТС\ТИ }
#out:
#  CVS
#=============================================
proc tmwgtway { tns usr pwd crn CVS } {
#=============================================
# глобальный список, куда пишем все результаты
  upvar $CVS lst ;

# Константы
  set zpr " ,.'\"" ; # запретные символы в названии

# Устанавливаем соединение к БД
  database db $tns $usr $pwd
#db set autocommit off

# Устанавливаем РОЛЬ
# по умолчанию = BASE_EXT_CONNECT_OIK CONNECT => SBOR_STAND_READ = (SELECT = da_dev_desc )  BASE_STAND_READ
  if {$usr!="rsduadmin"} {
    db "SET ROLE SBOR_STAND_READ , BASE_STAND_READ"
    db "select * from session_roles"
  }


  set sw [string repeat "=" 78 ]
  set lst [linsert $lst end "\n${sw}\n" ]
  set lst [linsert $lst end "!! Внимание: не должно быть на одном IP несколько одинаковых портов! (требование Scada)\n" ] ;
  set lst [linsert $lst end "Справочные данные:\n" ]
# получаем - Направления сбора = id + name + IP + Port
  set s1 "select id from da_type where define_alias like 'DEVICE'" ;
  set s2 "select tab.id_dirtbl from sys_tabl_v tab, sys_tree21 tr where tr.id_lsttbl =tab.id_lsttbl and upper (r_table) like 'DA_V_LST%'"
  set s0 "select t.id, t.name, i.id_dev, i.ip_addr, i.ip_port from da_cat t, da_slave i where i.id_node(+) = t.id and t.id_type in ($s1) and da_get_dirtbl_f (t.id) in ($s2) order by i.id_dev, t.id , i.ip_addr " ;

  set sl0 [ db $s0 ]

  foreach {x0} $sl0 {
    set sf [ format "%-10s %-40s %-10s %-17s  %-14s" [lindex $x0 0]  [lindex $x0 1] [lindex $x0 2] [lindex $x0 3] [lindex $x0 4] ] ;
    set lst [linsert $lst end "${sf}" ] ;
  }
  set lst [linsert $lst end "\n${sw}\n" ]

  set lst [linsert $lst end "\nFormat: СИГНАЛ,,,,,,,,,ГРУППА,session,ASDU,address,cvalif,,,formula,,,decription,\n" ]
  set lst [linsert $lst end "\n${sw}\n" ]

# список протоколов из DA_PROTO_DESC + индекс для адреса ASDU
#  select id, name from DA_PROTO_DESC where nvl(id_parent,-1)=-1 order by id ;
array unset PROTO_ASDU
array set PROTO_ASDU {
1   1
5   0
7   1
11    0
14    1
23    0
32    1
38    0
48    1
52    0
55    0
58    1
72    0
105   0
107   0
113   0
115   1
5000240 1
}

  set lst [linsert $lst end "\nВажно! Нумерация каналов сбора не привязана к Направлениям=Каналам сбора (табл. DA_CAT)\n" ]

  set id 1 ; # нумерация каналов сбора, так как номера устройств могут повторяться.

  # Обход по дереву НАПРАВЛЕНИЙ
  set id_dev  1
  set name  ""
  set str1 "select * from da_dev order by name" ; # первый вариант
  set str1 "select id_dev, name from da_dev_desc where nvl(id_parent,-1)=-1 order by id_dev" ; # второй вариант
  foreach {x} [ db $str1 ] {
    set sw [string repeat "-" 50 ]
    set lst [linsert $lst end "\n${sw}\n" ]

    # name
    set idName  [lindex $x 1]
    # id_dev
    set id_dev  [lindex $x 0]

    set sf [ format "%s=%-40s=%s:%s" $id_dev $idName "unknown" "unknown"] ;
    set lst [linsert $lst end "${sf}" ] ;

    set rec1 [split $idName $zpr] ; set rec2 [join $rec1 "" ] ; # Убираем спецсимволы
    set nm0 ${rec2} ; # название без пробелов для вывода в группу
    #if {$crn!=0} {
     set nm0 "SBOR${id_dev}" ;
    #}
    set lst [linsert $lst end "Alias=${nm0}" ] ;


    # Название Протоколов (на одном направлении возможен сбор с нескольких протоколов)
    # Выводим для справки
    set protocols {} ;
    set str56 "select da_proto_desc.id,da_proto_desc.name from da_dev_proto, da_proto_desc where da_dev_proto.id_dev=%ld  \
               and da_dev_proto.id_proto=da_proto_desc.id;"
    set fah56 [ format $str56 $id_dev ]
    set p0 [ db $fah56 ] ;# - id и имя протокола
    foreach {z} $p0 {
        set strP [ format "%s (%d)" [lindex $z 1] [lindex $z 0] ] ;
        set protocols [ linsert $protocols end $strP ];
    }
    set sf [ format "Протокол = %s" $protocols ] ;
    set lst [linsert $lst end "${sf}" ] ;


    # начинаем заполнять дерево элементов
    ::struct::tree mytreeID

    # первый элемент (корень)
    set str2 "select id,name,cvalif from da_dev_desc where id_dev=%ld and NVL(id_parent, -1)=-1 order by id"
    set fah2 [ format $str2  $id_dev ]
    foreach {x1} [ db $fah2 ] { mytreeID insert root end [lindex $x1 0] ; }
    # присоединяем - листья (условие прекращения = 0 листьев по всем веткам))
    set ss 1
    while {$ss} {
      set ss 0
      foreach {id} [ mytreeID leaves ] {
        if {$id=="root"} { continue ; }
        set str3 "select id from da_dev_desc where id_dev=%ld and id_parent=%ld and NVL(id_gtopt,-1)=-1 order by id"
        set fah3 [ format $str3 $id_dev $id ]
        set yl [ db $fah3 ]
        set ss [ expr $ss + [llength $yl] ]
        foreach {y} $yl {
          set v1 [lindex $y 0] ;
          mytreeID insert $id end $v1 ;
        }
      }
    }

    # = Вспомогательная информация =
    # Получаем Адреса ТИ+ТС+ТУ, а также, количество элементов у них
    set lsproto { } ;
    foreach {id21} [ mytreeID leaves ] {
        if {$id21=="root"} { continue ; }
        set str56 "select * from da_dev_desc where id_dev=%ld and id=%ld order by id"
        set fah56 [ format $str56 $id_dev $id21 ]
        set proto 0 ;
        foreach {z} [ db $fah56 ] { set proto [lindex $z 5] ; }
        # Получаем количество элементов протокол->общийадрес->адрес
        set str57 "select count(*) from da_dev_desc where id_dev=%ld and id_parent=%ld and id_gtopt>=1 order by id"
        set fah57 [ format $str57 $id_dev $id21 ]
        set protocnt 0 ;
        foreach {z} [ db $fah57 ] { set protocnt [lindex $z 0] ; }
        set lsproto [ linsert $lsproto end "$proto ($protocnt)" ];
    }
    set sf [ format "Адреса = %s" $lsproto ] ;
    set lst [linsert $lst end "${sf}\n" ] ;


    # обходим листья и получаем список элементов
    foreach {id2} [ mytreeID leaves ] {
      if {$id2=="root"} { continue ; }

      #------------------------------------------------------------------------------
      # id2->....->....->....->id{ASDU}->id{Протокол}->id{Направление=Устройство}->root
      set protoId 0
      set protoName "" ;
      set protoCvalif 1 ;

      set anc1 [ mytreeID ancestors $id2 ] ;
      set anc2 [ lreverse $anc1 ]
      set ll0 [llength $anc2] ;
      set num 2 ;
      if {$ll0==2} { set num 1; }
      if {$ll0==1} { set num 0; }
      set id23 [ lindex $anc2 $num ]
	  
      # получаем da_dev_desc.id протокола
      set str58 "select DPD.id, DPD.NAME, DD.CVALIF  from da_dev_desc dd, DA_PROTO_DESC dpd \
                      where dd.id_dev=%ld and dd.id=%ld and dpd.ID=dd.ID_PROTO_POINT"
      set fah58 [ format $str58 $id_dev $id23 ]
      foreach {z} [ db $fah58 ] {
        set protoId [lindex $z 0] ;
        set protoName [lindex $z 1] ;
        set protoCvalif [lindex $z 2] ;
      }

      # Получаем Общий Адрес протокола.
      # - на одном направлении - мб >=1 адресов ASDU
      # в зависимости от протокола ищем индекс, где начинается адрес ASDU
      set indexP 0
      foreach {idP indP} [array get PROTO_ASDU] {
         if {$idP==$protoId} { set indexP $indP ;}
      }
      # если 0, то адрес ASDU = адресу Протокола
      if {$indexP==0} {
        set idasdu $protoCvalif
      }
      # получаем da_dev_desc.id ASDU
      if {$indexP!=0} {
        set numA 3 ;
        if {$ll0<=3} { set numA 2; }
        if {$ll0<=2} { set numA 1; }
        set id23 [ lindex $anc2 $numA ]
        set str59 "select * from da_dev_desc dd where dd.id_dev=%ld and dd.id=%ld"
        set fah59 [ format $str59 $id_dev $id23 ]
        foreach {z} [ db $fah59 ] {
          set idasdu [lindex $z 5] ;
        }
      }

      # Получаем Адрес=Квалификатор для ТИ\ТС\ТУ , согласно МЭК
      set idproto 0
      set str55 "select * from da_dev_desc where id_dev=%ld and id=%ld order by id"
      set fah5 [ format $str55 $id_dev $id2 ]
      foreach {z} [ db $fah5 ] {
        set idproto [lindex $z 5] ;
      }

      # выбор сессии? в зависимости от протокола
      set session 1 ; # - по умолчанию принимаем
      # Если 104 = 4
      if {[regexp -- "104" $protoName]} { set session 4;}
      # Если 101 = 1
      if {[regexp -- "101" $protoName]} { set session 1;}
      # Если 103 = 1
      if {[regexp -- "103" $protoName]} { set session 1;}
      # Если modbus = 1
      if {[regexp -- "bus" $protoName]} { set session 1; set idasdu "" ; }


      #------------------------------------------------------------------------------


      # Получаем ВСЕ устройства\адреса для данного направления
      set str5 "select * from da_dev_desc where id_dev=%ld and id_parent=%ld and id_gtopt>=1 order by id"
      set fah5 [ format $str5 $id_dev $id2 ]
      set count 0
      foreach {z} [ db $fah5 ] {
        set did [lindex $z 0]
        set dproto [lindex $z 1]
        set dname [lindex $z 4]
        set dcvalif [lindex $z 5]
        set didtype [lindex $z 6] ; if {$didtype==""} { set didtype 0 ; }
        #
        #======================================================================================
        set fid 0 ; set formula "" ;
        set flbool [ list "bool(if(rand(0, 3, 900000),1,0))" \
                          "bool(if(rand(0, 3, 3600000),1,0))" \
                          "bool(1)" "bool(0)" \
                          "bool(if(rand(0, 3, 3600000),0,1))"  \
                          "equals(rand(0, 3, 900000),rand(0, 3, 800000))" \
                          "bool(if(rand(0, 10,100000),0,1))" \
                          "bool(square(0, 1, 600000))" \
                          "bool(if(rand(0, 5, 300000),0,1))" "bool(if(rand(0, 5,1800000),0,1))" ]
        set flanalog [ list "rand(1, 5, 60000)"  "saw(101,550,rand(1, 5, 60000),5000)"  \
                            "saw(0,100,1,5000)"  "17+rand(1000,2000,5000)*0.01" \
                            "rand(0, 500, 90000)"  "rand(0, 1000, 900000)*0.15" \
                            "saw(101,550,rand(1, 5, 60000),5000)" "rand(1, 100, 200000)" \
                            "rand(1,5, 10000)*1000"  "saw(20,50,2,15000)"  "rand(0,1000,20000)" \
                            "rand(0,1,600000)"  "if(rand(0, 3, 90000),1,0)" \
                            "saw(4900,5000,5,10000)*0.01"  \
                            "rand(1000,1300,30000)*0.01"  \
                            "saw(100,250,3,70000)*0.1"  \
                            "rand(0,5,3500)"  \
                            "float(0.64*rand(0, 3, 90000))"  \
                            "float(rand(0,17, 600000)*0.1)"  \
                            "rand(1,3500, 600000)*0.01" \
                            "long(15+rand(1,10, 60000)*0.55)" ]
        set fldigit [ list "if(rand(0, 3, 9000),1,0))"  "int(1)" "int(0)" \
                            "rand(0, 500, 9000)" "rand(0, 1000, 600000)" "float(327.68)" \
                            "rand(1,5, 5000)*2500" "rand(0,11132,2000)" \
                            "saw(4900,5000,5,10000)*0.01"  \
                            "rand(1000,1300,30000)*0.01"  \
                            "long(rand(1,10, 60000)*5.3)" ]
        set flstring [ list "test1"  "test5" "test6" \
                            "test9"  "32768" "char(8)" \
                            "Hello World"  ]
        #======================================================================================

        # Получаем тип сигнала
        set dalias ""
        set str6 "select sys_gtyp.define_alias from sys_dtyp , sys_gtyp where sys_dtyp.id=%ld and sys_dtyp.ID_GTYPE=sys_gtyp.ID"
        set fah6 [ format $str6 $didtype ]
        foreach {z2} [ db $fah6 ] { set dalias [lindex $z2 0] ; }
        # В зависимости от типа сигнала установим префикс имени
        set name_prefics "P"
        switch $dalias {
            "GLOBAL_TYPE_ANALOG" {
              set name_prefics "TI"
              set fid [ llength $flanalog ];
              set fid [ expr {0+round(rand()*($fid-1))} ];
              set formula [ lindex $flanalog $fid ];
            }
            "GLOBAL_TYPE_DIGIT" {
              set name_prefics "TI"
              set fid [ llength $fldigit ];
              set fid [ expr {0+round(rand()*($fid-1))} ];
              set formula [ lindex $fldigit $fid ];
            }
            "GLOBAL_TYPE_BOOL" {
              set name_prefics "TC"
              set fid [ llength $flbool ];
              set fid [ expr {0+round(rand()*($fid-1))} ];
              set formula [ lindex $flbool $fid ];
            }
            "GLOBAL_TYPE_DANALOG" {
              set name_prefics "TI"
              set fid [ llength $flanalog ];
              set fid [ expr {0+round(rand()*($fid-1))} ];
              set formula [ lindex $flanalog $fid ];
            }
            "GLOBAL_TYPE_DDIGIT" {
              set name_prefics "TI"
              set fid [ llength $fldigit ];
              set fid [ expr {0+round(rand()*($fid-1))} ];
              set formula [ lindex $fldigit $fid ];
            }
            "GLOBAL_TYPE_DBOOL" {
              set name_prefics "TC"
              set fid [ llength $flbool ];
              set fid [ expr {0+round(rand()*($fid-1))} ];
              set formula [ lindex $flbool $fid ];
            }
            "GLOBAL_TYPE_STRING" {
              set name_prefics "T"
              set fid [ llength $flstring ];
              set fid [ expr {0+round(rand()*($fid-1))} ];
              set formula [ lindex $flstring $fid ];
            }
            default {  ;  }
        }

        #СИГНАЛ,,,,,,,,,ГРУППА,session,ASDU,address,cvalif,,,formula,,,decription,
        set rec1 [split $dname $zpr ] ; set rec2 [join $rec1 "" ] ; # Убираем спецсимволы
        set nm1 "${rec2}${did}" ; set nm1decr ${nm1} ;
        if {$crn!=0} {  set nm1 "${name_prefics}${dcvalif}" ; set nm1decr ${nm1} ; }
        set lst [linsert $lst end "${nm1},,,,,,,,,${nm0},${session},${idasdu},${idproto},${dcvalif},,,\"${formula}\",,,${nm1decr}," ]

        incr count
      }
      set sf [ format "id_dev=%-15s=%-40s  (%10s)"  ${id_dev}  ${idName}  ${count} ]
      puts $sf
    }


    mytreeID destroy
  }


# Закрываем соединение к БД
#db commit
  db disconnect

  return 0 ;
}


#=============================================
proc tmwgtwayMain { } {
#=============================================
global   tcl_platform
#============================ задаем константы
  set tns "rsdu2"
  set usr "rsduadmin" ; #  admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz
  set crn 1 ; # 0 - обычные имена как в БД, иное - шаблон ТС\ТИ
  set saveFile 1 ; # запись в файл
  set nameFile "tmwgtway_rsdu2_dev.txt" ; # имя файла для сохранения результата
#=============================================

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nstart = $t1\n"

  set ls {};
  set ret [ tmwgtway $tns $usr $pwd $crn ls ]

  if {$saveFile == 1} {
    # формируем название файла
    set path [info script]
    set path [ file normalize $path ]
    set dirname [ file dirname $path ]
    set f0 [file join $dirname $nameFile ]
    set f [ file nativename $f0 ]
    # открываем на перезапись в файл
    set fd [ open $f "w+"]
      for {set ind 0} {$ind<[llength $ls]} {incr ind} {
        puts $fd [lindex $ls $ind ] ;
      }
      flush $fd
      close $fd
      if { [file exists $f] == 1} {
         puts "\n File $f created!" ;
      }
  } else {
    for {set ind 0} {$ind<[llength $ls]} {incr ind} {
      puts [lindex $ls $ind ] ;
    }
  }

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nend = $t1"

  return 0 ;
}


tmwgtwayMain












