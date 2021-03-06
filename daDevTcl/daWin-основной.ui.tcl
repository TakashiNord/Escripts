# interface generated by SpecTcl version 1.1 from Z:/daDevTcl/daWin.ui
#   root     is the parent window for this user interface

proc daWin_ui {root args} {

	# this treats "." as a special case

	if {$root == "."} {
	    set base ""
	} else {
	    set base $root
	}
    
	button $base.button#1 \
		-command fileOpen \
		-text {File Open}

	entry $base.entry#2 \
		-textvariable fileNameLabel

	button $base.button#4 \
		-command GetListId \
		-text {Get List Id}

	label $base.label#1 \
		-text Id=

	entry $base.entry#3 \
		-textvariable idLabel

	radiobutton $base.radiobutton#1 \
		-text {TI} \
		-value 1 \
		-variable radio

	radiobutton $base.radiobutton#2 \
		-text {TC} \
		-value 0 \
		-variable radio

	button $base.button#2 \
		-command GetSqlFile \
		-text {Get Sql File}

	button $base.button#3 \
		-command InsertToDB \
		-text {Insert to DB}

	text $base.text#1 \
		-cursor {} \
		-height 1 \
		-width 1


	# Geometry management

	grid $base.button#1 -in $root	-row 1 -column 1  \
		-sticky nesw
	grid $base.entry#2 -in $root	-row 1 -column 2  \
		-sticky nesw
	grid $base.button#4 -in $root	-row 1 -column 3  \
		-sticky nesw
	grid $base.label#1 -in $root	-row 1 -column 4  \
		-sticky nesw
	grid $base.entry#3 -in $root	-row 1 -column 5  \
		-sticky nesw
	grid $base.radiobutton#1 -in $root	-row 1 -column 6  \
		-sticky nesw
	grid $base.radiobutton#2 -in $root	-row 1 -column 7  \
		-sticky nesw
	grid $base.button#2 -in $root	-row 1 -column 8  \
		-sticky nesw
	grid $base.button#3 -in $root	-row 1 -column 9  \
		-sticky nesw
	grid $base.text#1 -in $root	-row 2 -column 1  \
		-columnspan 9 \
		-sticky nesw

	# Resize behavior management

	grid rowconfigure $root 1 -weight 0 -minsize 28
	grid rowconfigure $root 2 -weight 0 -minsize 602
	grid columnconfigure $root 1 -weight 0 -minsize 53
	grid columnconfigure $root 2 -weight 0 -minsize 229
	grid columnconfigure $root 3 -weight 0 -minsize 75
	grid columnconfigure $root 4 -weight 0 -minsize 50
	grid columnconfigure $root 5 -weight 0 -minsize 55
	grid columnconfigure $root 6 -weight 0 -minsize 36
	grid columnconfigure $root 7 -weight 0 -minsize 43
	grid columnconfigure $root 8 -weight 0 -minsize 89
	grid columnconfigure $root 9 -weight 0 -minsize 281
# additional interface code

package require struct::tree
package require tclodbc

global fileNameLabel
global idLabel
global radio

set radio 1 ;
#--------------------
proc InsertToDB { } {
#--------------------
 global fileNameLabel
 global idLabel
 global radio

 if {0==[file exists $fileNameLabel]} {
   tk_messageBox -message "no file" -type ok
   return 0
 }

 if {$idLabel==""} {
   tk_messageBox -message "no ID" -type ok
   return 0
 }
 
 if {$radio==""} {
   tk_messageBox -message "no TI\TC" -type ok
   return 0
 }

 doDev 2
 
 tk_messageBox -message "Ready" -type ok

}
#--------------------
proc GetSqlFile { } {
#--------------------
 global fileNameLabel
 global idLabel
 global radio

 if {0==[file exists $fileNameLabel]} {
   tk_messageBox -message "no file" -type ok
   return 0
 }

 if {$idLabel==""} {
   tk_messageBox -message "no ID" -type ok
   return 0
 }
 
 if {$radio==""} {
   tk_messageBox -message "no TI\TC" -type ok
   return 0
 }

 doDev 1
 
 tk_messageBox -message "Ready" -type ok

}

#--------------------
proc fileOpen { } {
#--------------------
 global fileNameLabel
 set types {
    {{Text Files}       {.csv}        }
    {{All Files}        *             }
 }
 set filename [tk_getOpenFile -filetypes $types]
 if {$filename==""} { return ; }
 # Open the file ...
 set fileNameLabel $filename
 update
 
}


#=============================================
proc da_dev1 { tns usr pwd crn CVS } {
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

    set sf [ format "%s=%-40s" $id_dev $idName ] ;
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

    foreach {id56} [ mytreeID leaves ] {
        if {$id56=="root"} { continue ; }
        set str56 "select * from da_dev_desc where id_dev=%ld and id=%ld order by id"
		set fah56 [ format $str56 $id_dev $id56 ]
        set y56 [ db $fah56 ]
        foreach {y} $y56 {
          set s0 [lindex $y 0] ;
		  #set s1 [lindex $y 1] ;
		  #set s2 [lindex $y 2] ;
		  #set s3 [lindex $y 3] ;
		  set s4 [lindex $y 4] ;
		  set s5 [lindex $y 5] ;
		  #set s6 [lindex $y 6] ;
		  set lst [linsert $lst end "${s0}=${s4} " ] ;
        }
	}

    mytreeID destroy
  }


# Закрываем соединение к БД
#db commit
  db disconnect

  return 0 ;
}

#--------------------
proc GetListId { } {
#--------------------
  catch { .text#1 delete 1.0 end ;  }
  .text#1 insert 0.0 "\n"

global   tcl_platform
#============================ задаем константы
  set tns "rsdu2"
  set usr "rsduadmin" ; #  admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz
  set crn 1 ; # 0 - обычные имена как в БД, иное - шаблон ТС\ТИ
  set saveFile 1 ; # запись в файл
  set nameFile "da_dev1.txt" ; # имя файла для сохранения результата
#=============================================

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nstart = $t1\n"

  set ls {};
  set ret [ da_dev1 $tns $usr $pwd $crn ls ]

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
		.text#1 insert end "[lindex $ls $ind ]\n" ;
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

 .text#1 mark set insert 0.0

 update;


}


#=============================================
proc da_dev2 { tns usr pwd fsql CVS id_parent saveFile radiots } {
#=============================================
# глобальный список, куда пишем все результаты
  upvar $CVS lst ;

# Устанавливаем соединение к БД
  database db $tns $usr $pwd
#db set autocommit off

# Устанавливаем РОЛЬ
# по умолчанию = BASE_EXT_CONNECT_OIK CONNECT => SBOR_STAND_READ = (SELECT = da_dev_desc )  BASE_STAND_READ
  if {$usr!="rsduadmin"} {
    db "SET ROLE SBOR_STAND_READ , BASE_STAND_READ"
    db "select * from session_roles"
  }

# получаем id_proto_point + id_dev  
  set id_proto_point -1 ;
  set id_dev -1 ;
  set str2 "select * from da_dev_desc where id=%ld order by id"
  set res2 [ format $str2 $id_parent ]
  set y2 [ db $res2 ]
  foreach {y} $y2 {
    set id_proto_point [lindex $y 1] ;
	set id_dev [lindex $y 2] ;
  }  
  
  if {$id_dev<0} {  puts " \n\n id_dev====$id_dev \n\n" ;  return -1; }
  if {$id_proto_point<0} {  puts " \n\n id_proto_point====$id_proto_point \n\n" ;  return -1; }

# получаем id_proto_point
  set str3 "select id from da_proto_desc where id_parent=$id_proto_point" ; # where id_parent=%ld
  set y3 [ db $str3 ]
  foreach {y} $y3 {
    set id_proto_point [lindex $y 0] ;
  } 
  
# получаем max ID
  set maxId 0
  set str1 "select max(id) from da_dev_desc" ; #
  set y1 [ db $str1 ]
  foreach {y} $y1 {
    set maxId [lindex $y 0] ;
  }  
  puts " \n max(Id)=$maxId \n" ;
  
  if {$saveFile==1} { set df [ open $fsql "w+"] ; }
  
# формируем строки для вставки
  for {set ind 0} {$ind<[llength $lst]} {incr ind} {
  
    set maxId [ expr $maxId+1 ] 
  
    set s0 [lindex $lst $ind ] ;
    set pl [ split $s0 ";" ]
	if {[llength $pl]<2} { continue ; }
	set name [lindex $pl 0 ] ;
	set cvalif [lindex $pl 1 ] ;
	set tcode "" ;
	catch { set tcode [lindex $pl 2 ] ; } err

	# ID_GTOPT = sys_gtopt.id
	# 1 = мгновенные аналоговые
	# 8 = мгновенные булевые
	set ID_GTOPT 1
	if {0==[string compare $tcode "тс"]} { set ID_GTOPT 8 ; }
	if {0==[string compare $tcode "ТС"]} { set ID_GTOPT 8 ; }
	if {0==[string compare $tcode "Тс"]} { set ID_GTOPT 8 ; }
	if {0==[string compare $tcode "тС"]} { set ID_GTOPT 8 ; }

	if {$radiots==0} { set ID_GTOPT 8 ; }

	
	# ID_TYPE = sys_dtype.id
	# --------------------------
	# 405 - базовый аналоговый
	# 7 - напряжение
	# 5 - ток
	# 6 - реактивная мощность Q
	# 8 - активная мощность P
	# --------------------------
	# 406 - базовый булевой
	# 
	# 
	set ID_TYPE 0
	if {$ID_GTOPT==1} {
	   set ID_TYPE 405
	   if {[regexp "Ia" $name]} { set ID_TYPE 5 }
	   if {[regexp "Ib" $name]} { set ID_TYPE 5 }
	   if {[regexp "Ic" $name]} { set ID_TYPE 5 }
	   if {[regexp "Ua" $name]} { set ID_TYPE 7 }
	   if {[regexp "Ub" $name]} { set ID_TYPE 7 }
	   if {[regexp "Uc" $name]} { set ID_TYPE 7 }
	   if {[regexp "Uab" $name]} { set ID_TYPE 7 }
	   if {[regexp "Ubc" $name]} { set ID_TYPE 7 }
	   if {[regexp "Uca" $name]} { set ID_TYPE 7 }
	   if {[regexp "P" $name]} { set ID_TYPE 8 }
	   if {[regexp "Q" $name]} { set ID_TYPE 6 }
	}
    if {$ID_GTOPT==8} {
	   set ID_TYPE 406
    }	

	set strSQL "Insert into DA_DEV_DESC (ID, ID_PROTO_POINT, ID_DEV, ID_PARENT, NAME, CVALIF, ID_TYPE, ID_GTOPT, ATTR_NAME) \
        Values  (${maxId}, ${id_proto_point}, ${id_dev}, ${id_parent}, '${name}', ${cvalif}, ${ID_TYPE}, ${ID_GTOPT}, NULL);"
	if {$saveFile==1} { puts $df $strSQL ; } 
	if {$saveFile>1} { db $strSQL ; }
	puts "${strSQL}"
	
  }  
 
  if {$saveFile==1} {  flush $df ; close $df  ; }
 # Закрываем соединение к БД
  if {$saveFile>1} {  db commit ; }
  db disconnect

  return 0 ;
}



#--------------------
proc doDev { flag } {
#--------------------
 global fileNameLabel
 global idLabel
 global radio

global   tcl_platform
#============================ задаем константы
  set tns "rsdu2"
  set usr "rsduadmin" ; #  admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz
  set nameFile "da_dev2.sql" ; # имя файла для сохранения результата
  set nameFileCSV "Книга1.csv" ; # имя файла для сохранения результата
  set saveFile 1 ; # 1-писать в файл-sql. или 2-commit в базу ; 0- никуда
#=============================================

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nstart = $t1\n"

  set ls {} ; #[ list ]
  
  # формируем название файла
  set path [info script]
  set path [ file normalize $path ]
  set dirname [ file dirname $path ]
  set fsql [file join $dirname $nameFile ]
  #set f0 [file join $dirname $nameFileCSV ]
  set f0 $fileNameLabel
  set f [ file nativename $f0 ]
  # открываем на перезапись в файл
  set fd [ open $f "r"]
  while {![eof $fd]} {
	 gets $fd data
	 set ls [linsert $ls end "${data}" ] ;
  }
  close $fd
  
  set id_parent $idLabel  
  set ret [ da_dev2 $tns $usr $pwd $fsql ls $id_parent $flag $radio]

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nend = $t1"

  return 0 ;

}



 update



# end additional interface code

}


# Allow interface to be run "stand-alone" for testing

catch {
    if [info exists embed_args] {
	# we are running in the plugin
	daWin_ui .
    } else {
	# we are running in stand-alone mode
	if {$argv0 == [info script]} {
	    wm title . "Testing daWin_ui"
	    daWin_ui .
	}
    }
}
