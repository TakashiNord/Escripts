

package require tclodbc
package require sqlite3

set tns "rsdu2"
set usr "rsduadmin" ; #  admin  nov_ema
set pwd "passme" ; # passme  qwertyqaz

puts "-- Start --"

global db2

set t1 [ clock format [ clock seconds ] -format "%Y%m%d_%H%M%S" ]
puts "\nstart = $t1\n"

# лог - файл
  set ph [info script]
  if {$ph==""} {
    set ph rsduadmin_change_id_${t1}.log
  } else {
    set ph [file rootname $ph ]_${t1}.log
  }

proc LogWrite  { s } {
  global rf
  if {![info exists rf]} { return }
  if {$rf==""} { return }
  puts $rf $s
}

 set rf [ open $ph "w+"  ]

# Устанавливаем соединение к БД
 database db2 $tns $usr $pwd
 db2 set autocommit off

 set owner "RSDUADMIN"

# Устанавливаем РОЛЬ
# по умолчанию = BASE_EXT_CONNECT_OIK CONNECT => SBOR_STAND_READ
  if {$usr!="rsduadmin"} {
    db2 "SET ROLE SBOR_STAND_READ , BASE_STAND_READ"
    db2 "select * from session_roles"
  }



# --
proc checkTable { rf db2 tblname col } {
  set strSQL1 "SELECT count($col) FROM $tblname"
  set df ""
  set err ""
  catch {
    set df [ $db2 $strSQL1 ]
    set p ""
  } err
  puts "-- $tblname  -- $df "
  if {$err!=""} { return 0 ; }
  return 1 ;
}


# ==============================================================================================================

# --
proc BASE1 { rf db2 } {

  set TABLE_LIST [ list OBJ_MODEL_MEAS \
 RSDU_UPDATE RSDU_ERROR \
 DA_SLAVE DA_MASTER DA_DEV_OPT DA_PC DA_PORT \
 MEAS_EL_DEPENDENT_SVAL \
 AD_SINFO_INI \
 SYS_APP_SERV_LST SYS_APP_SERVICES SYS_APP_SSYST SYS_APP_INI \
 US_ZONE US_VARS US_SIGN_PROP US_SIGN_GROUP US_SIG US_MSGLOG ]


  foreach TABLE_NAME $TABLE_LIST {

    set strSQL1 "SELECT max(ID), min(ID), count(*) FROM $TABLE_NAME"

    set maxID 0 ; set minID 0 ; set cntID 0 ;
    foreach {r1} [ $db2 $strSQL1 ] {
      set maxID [ lindex $r1 0 ]
      set minID [ lindex $r1 1 ]
      set cntID [ lindex $r1 2 ]
      set s1 "\n$TABLE_NAME = max=$maxID min=$minID cnt=$cntID "
      puts $s1
    }

    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {

        LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"
		
		set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
        $db2 $strSQL3
        $db2 commit

      }
    }

    set strSQL3 "SELECT ${TABLE_NAME}_S.nextval FROM dual"
    set r3 [ $db2 $strSQL3 ]
    set l3 [ llength $r3 ]
    if {$l3>0} {
     set increment_old [lindex $r3 0 ]
     set increment_old [ expr (int($increment_old)-1)*(-1) ]
     set str2 [ format "alter sequence %s_S increment by %d" $TABLE_NAME $increment_old ]
     $db2 $str2
     $db2 $strSQL3
     $db2 "alter sequence ${TABLE_NAME}_S increment by 1"
    }

  }

 return 0 ;
}



# ==============================================================================================================


# -- SYS_APD
proc SYS_APD { rf db2 } {

  set TABLE_LIST [ list SYS_APD ]

  foreach TABLE_NAME $TABLE_LIST {

    set strSQL1 "SELECT max(ID), min(ID), count(*) FROM $TABLE_NAME"

    set maxID 0 ; set minID 0 ; set cntID 0 ;
    foreach {r1} [ $db2 $strSQL1 ] {
      set maxID [ lindex $r1 0 ]
      set minID [ lindex $r1 1 ]
      set cntID [ lindex $r1 2 ]
      set s1 "\n$TABLE_NAME = max=$maxID min=$minID cnt=$cntID \n"
      puts $s1
    }

    set maxID [ expr int($maxID)+1 ]
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_PARENT,ID_TYPE,NAME,ALIAS) VALUES ($maxID,NULL,1,'TEXTRENAMETEXT','') "
    $db2 $strSQL0
    $db2 commit

    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {
	  
	   LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

       #--$TABLE_NAME
       $db2 "UPDATE $TABLE_NAME SET ID_PARENT=$maxID WHERE ID_PARENT=$id_old"
       $db2 commit
       #--SYS_APPL
       $db2 "UPDATE SYS_APPL SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
       $db2 commit

       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

       #--SYS_APPL
       $db2 "UPDATE SYS_APPL SET ID_NODE=$j WHERE ID_NODE=$maxID"
       $db2 commit
       #--$TABLE_NAME
       $db2 "UPDATE $TABLE_NAME SET ID_PARENT=$j WHERE ID_PARENT=$maxID"
       $db2 commit

      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE NAME LIKE '%TEXTRENAMETEXT%' "
    $db2 commit

    set strSQL3 "SELECT ${TABLE_NAME}_S.nextval FROM dual"
    set r3 [ $db2 $strSQL3 ]
    set l3 [ llength $r3 ]
    if {$l3>0} {
     set increment_old [lindex $r3 0 ]
     set increment_old [ expr (1-int($increment_old)) ]
     set str2 [ format "alter sequence %s_S increment by %d" $TABLE_NAME $increment_old ]
     $db2 $str2
     $db2 $strSQL3
     $db2 "alter sequence ${TABLE_NAME}_S increment by 1"
    }

  }

 return 0 ;
}




# ==============================================================================================================

proc VP_GROUP { rf db2 } {

  set TABLE_LIST [ list VP_GROUP ]

  foreach TABLE_NAME $TABLE_LIST {

    set strSQL1 "SELECT max(ID), min(ID), count(*) FROM $TABLE_NAME"

    set maxID 0 ; set minID 0 ; set cntID 0 ;
    foreach {r1} [ $db2 $strSQL1 ] {
      set maxID [ lindex $r1 0 ]
      set minID [ lindex $r1 1 ]
      set cntID [ lindex $r1 2 ]
      set s1 "\n$TABLE_NAME = max=$maxID min=$minID cnt=$cntID \n"
      puts $s1
    }

    set maxID [ expr int($maxID)+1 ]
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_PARENT,ID_TYPE,NAME,ALIAS) VALUES ($maxID,NULL,1,'TEXTRENAMETEXT','') "
    $db2 $strSQL0
    $db2 commit


    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {
	  
	   LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

       #--VP_GROUP
       $db2 "UPDATE VP_GROUP SET ID_PARENT=$maxID WHERE ID_PARENT=$id_old"
       $db2 commit
       #--VP_PANEL
       $db2 "UPDATE VP_PANEL SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
       $db2 commit

       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

       #--VP_PANEL
       $db2 "UPDATE VP_PANEL SET ID_NODE=$j WHERE ID_NODE=$maxID"
       $db2 commit
       #--VP_GROUP
       $db2 "UPDATE VP_GROUP SET ID_PARENT=$j WHERE ID_PARENT=$maxID"
       $db2 commit

      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE NAME LIKE '%TEXTRENAMETEXT%' "
    $db2 commit

    set strSQL3 "SELECT ${TABLE_NAME}_S.nextval FROM dual"
    set r3 [ $db2 $strSQL3 ]
    set l3 [ llength $r3 ]
    if {$l3>0} {
     set increment_old [lindex $r3 0 ]
     set increment_old [ expr (1-int($increment_old)) ]
     set str2 [ format "alter sequence %s_S increment by %d" $TABLE_NAME $increment_old ]
     $db2 $str2
     $db2 $strSQL3
     $db2 "alter sequence ${TABLE_NAME}_S increment by 1"
    }

  }

 return 0 ;
}


#  -- VP_PANEL  - необходимо проверить ID_TABLE=40 - VP_PANEL , ID_APPL=87 - pnview.exe
proc VP_PANEL { rf db2 ID_TABLE ID_APPL } {

  set TABLE_LIST [ list VP_PANEL ]

  foreach TABLE_NAME $TABLE_LIST {

    set strSQL1 "SELECT max(ID), min(ID), count(*) FROM $TABLE_NAME"

    set maxID 0 ; set minID 0 ; set cntID 0 ;
    foreach {r1} [ $db2 $strSQL1 ] {
      set maxID [ lindex $r1 0 ]
      set minID [ lindex $r1 1 ]
      set cntID [ lindex $r1 2 ]
      set s1 "\n$TABLE_NAME = max=$maxID min=$minID cnt=$cntID \n"
      puts $s1
    }

    set maxID [ expr int($maxID)+1 ]
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_NODE,ID_TYPE,NAME,ALIAS,NAME_UIR,ID_GTOPT,LAST_UPDATE,LAST_ACCESS) VALUES ($maxID,NULL,522,'TEXTRENAMETEXT','','TEXTRENAMETEXT',9,0,0) "
    $db2 $strSQL0
    $db2 commit


    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {
	  
	   LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

       #--VP_CTRL
       $db2 "UPDATE VP_CTRL SET ID_PANEL=$maxID WHERE ID_PANEL=$id_old"
       $db2 commit

       #--US_MENU  ID_APPL=87 - pnview.exe
       $db2 "UPDATE US_MENU SET ID_PARAM=$maxID WHERE ID_PARAM=$id_old AND ID_APPL=$ID_APPL"
       $db2 commit

       #--VP_PARAMS  ID_TABLE=40 - VP_PANEL_LST
       $db2 "UPDATE VP_PARAMS SET ID_PARAM=$maxID WHERE ID_PARAM=$id_old AND ID_TABLE=$ID_TABLE"
       $db2 commit

       #--VS_REGIM_TUNE  ID_TABLE=40 - VP_PANEL_LST
       $db2 "UPDATE VS_REGIM_TUNE SET ID_PARAM=$maxID WHERE ID_PARAM=$id_old AND ID_TABLE=$ID_TABLE"
       $db2 commit


       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

        #SYS_APPL ( ALIAS )
        # pnview.exe /168
		set strSQL9 "SELECT ID, ALIAS FROM SYS_APPL"
		set r9all [ $db2 $strSQL9 ]
        foreach {r9} $r9all {
           set mID [ lindex $r9 0 ]
           set mALIAS [ lindex $r9 1 ]
		   set ret1 [ regexp -nocase -- "pnview" $mALIAS ]
		   if {$ret1>0} {
		    set ln "\\y$id_old\\y"
			set ret2 [ regexp -all -- $ln $mALIAS ]
		    if {$ret2>0} {
			    set mALIAS_new ""
			    set ln_new "$j"
			    set ret3 [ regsub -nocase -all -- $ln $mALIAS $ln_new mALIAS_new ]
				if {$ret3>0} { 
				    #
			        $db2 "UPDATE SYS_APPL SET ALIAS='${mALIAS_new}' WHERE ID=$mID"
				    $db2 commit
				    #
			        LogWrite "SYS_APPL (ID=${mID}) old='${mALIAS}'  new='${mALIAS_new}' "
			    }
			}   
		   }		   
        }


       #--VP_CTRL
       $db2 "UPDATE VP_CTRL SET ID_PANEL=$j WHERE ID_PANEL=$maxID"
       $db2 commit

       #--US_MENU  ID_APPL=87 - pnview.exe
       $db2 "UPDATE US_MENU SET ID_PARAM=$j WHERE ID_PARAM=$maxID AND ID_APPL=$ID_APPL"
       $db2 commit

       #--VP_PARAMS  ID_TABLE=40 - VP_PANEL_LST
       $db2 "UPDATE VP_PARAMS SET ID_PARAM=$j WHERE ID_PARAM=$maxID AND ID_TABLE=$ID_TABLE"
       $db2 commit

       #--VS_REGIM_TUNE  ID_TABLE=40 - VP_PANEL_LST
       $db2 "UPDATE VS_REGIM_TUNE SET ID_PARAM=$j WHERE ID_PARAM=$maxID AND ID_TABLE=$ID_TABLE"
       $db2 commit


      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE NAME LIKE '%TEXTRENAMETEXT%' "
    $db2 commit

    set strSQL3 "SELECT ${TABLE_NAME}_S.nextval FROM dual"
    set r3 [ $db2 $strSQL3 ]
    set l3 [ llength $r3 ]
    if {$l3>0} {
     set increment_old [lindex $r3 0 ]
     set increment_old [ expr (1-int($increment_old)) ]
     set str2 [ format "alter sequence %s_S increment by %d" $TABLE_NAME $increment_old ]
     $db2 $str2
     $db2 $strSQL3
     $db2 "alter sequence ${TABLE_NAME}_S increment by 1"
    }

  }

 return 0 ;
}



# ==============================================================================================================


# -- VS_GROUP
proc VS_GROUP { rf db2 } {

  set TABLE_LIST [ list VS_GROUP ]

  foreach TABLE_NAME $TABLE_LIST {

    set strSQL1 "SELECT max(ID), min(ID), count(*) FROM $TABLE_NAME"

    set maxID 0 ; set minID 0 ; set cntID 0 ;
    foreach {r1} [ $db2 $strSQL1 ] {
      set maxID [ lindex $r1 0 ]
      set minID [ lindex $r1 1 ]
      set cntID [ lindex $r1 2 ]
      set s1 "\n$TABLE_NAME = max=$maxID min=$minID cnt=$cntID \n"
      puts $s1
    }

    set maxID [ expr int($maxID)+1 ]
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_PARENT,ID_TYPE,NAME,ALIAS) VALUES ($maxID,NULL,1,'TEXTRENAMETEXT','') "
    $db2 $strSQL0
    $db2 commit


    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {
	  
	   LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

       #--VS_GROUP
       $db2 "UPDATE VS_GROUP SET ID_PARENT=$maxID WHERE ID_PARENT=$id_old"
       $db2 commit
       #--VS_FORM
       $db2 "UPDATE VS_FORM SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
       $db2 commit

       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

       #--VS_FORM
       $db2 "UPDATE VS_FORM SET ID_NODE=$j WHERE ID_NODE=$maxID"
       $db2 commit
       #--VS_GROUP
       $db2 "UPDATE VS_GROUP SET ID_PARENT=$j WHERE ID_PARENT=$maxID"
       $db2 commit

      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE NAME LIKE '%TEXTRENAMETEXT%' "
    $db2 commit

    set strSQL3 "SELECT ${TABLE_NAME}_S.nextval FROM dual"
    set r3 [ $db2 $strSQL3 ]
    set l3 [ llength $r3 ]
    if {$l3>0} {
     set increment_old [lindex $r3 0 ]
     set increment_old [ expr (1-int($increment_old)) ]
     set str2 [ format "alter sequence %s_S increment by %d" $TABLE_NAME $increment_old ]
     $db2 $str2
     $db2 $strSQL3
     $db2 "alter sequence ${TABLE_NAME}_S increment by 1"
    }

  }

 return 0 ;
}


#  -- VS_FORM  - необходимо проверить ID_TABLE=43 - VS_FORM_LST , ID_APPL=1232 - schemeviewer.exe
proc VS_FORM { rf db2 ID_TABLE ID_APPL } {

  set TABLE_LIST [ list VS_FORM ]

  foreach TABLE_NAME $TABLE_LIST {

    set strSQL1 "SELECT max(ID), min(ID), count(*) FROM $TABLE_NAME"

    set maxID 0 ; set minID 0 ; set cntID 0 ;
    foreach {r1} [ $db2 $strSQL1 ] {
      set maxID [ lindex $r1 0 ]
      set minID [ lindex $r1 1 ]
      set cntID [ lindex $r1 2 ]
      set s1 "\n$TABLE_NAME = max=$maxID min=$minID cnt=$cntID \n"
      puts $s1
    }

    set maxID [ expr int($maxID)+1 ]
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_NODE,ID_TYPE,NAME,ALIAS,FILE_NAME,LAST_UPDATE,LAST_ACCESS) VALUES ($maxID,NULL,520,'TEXTRENAMETEXT','','TEXTRENAMETEXT',0,0) "
    $db2 $strSQL0
    $db2 commit

    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {
	  
	   LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

       #--VS_COMP
       $db2 "UPDATE VS_COMP SET ID_FORM=$maxID WHERE ID_FORM=$id_old"
       $db2 commit
       #--VS_OBJ_TUNE  ++++++
       $db2 "UPDATE VS_OBJ_TUNE SET ID_FORM=$maxID WHERE ID_FORM=$id_old"
       $db2 commit
       #--VS_MODUS_NODE 
       $db2 "UPDATE VS_MODUS_NODE  SET ID_FORM=$maxID WHERE ID_FORM=$id_old"
       $db2 commit	 
       #--VS_FORM_INIPARAMS  
       $db2 "UPDATE VS_FORM_INIPARAMS   SET ID_FORM=$maxID WHERE ID_FORM=$id_old"
       $db2 commit		   
       
	   #--US_MENU  ID_APPL=1232 - schemeviewer.exe
       $db2 "UPDATE US_MENU SET ID_PARAM=$maxID WHERE ID_PARAM=$id_old AND ID_APPL=$ID_APPL"
       $db2 commit
       #--VP_PARAMS  ID_TABLE=43 - VS_FORM_LST
       $db2 "UPDATE VP_PARAMS SET ID_PARAM=$maxID WHERE ID_PARAM=$id_old AND ID_TABLE=$ID_TABLE"
       $db2 commit
       #--VS_REGIM_TUNE  ID_TABLE=43 - VS_FORM_LST
       $db2 "UPDATE VS_REGIM_TUNE SET ID_PARAM=$maxID WHERE ID_PARAM=$id_old AND ID_TABLE=$ID_TABLE"
       $db2 commit


       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

        #SYS_APPL ( ALIAS )
        # schemeviewer.exe /168
		set strSQL9 "SELECT ID, ALIAS FROM SYS_APPL"
		set r9all [ $db2 $strSQL9 ]
        foreach {r9} $r9all {
           set mID [ lindex $r9 0 ]
           set mALIAS [ lindex $r9 1 ]
		   set ret1 [ regexp -nocase -- "schemeviewer" $mALIAS ]
		   if {$ret1>0} {
		    set ln "\\y$id_old\\y"
			set ret2 [ regexp -all -- $ln $mALIAS ]
		    if {$ret2>0} {
			    set mALIAS_new ""
			    set ln_new "$j"
			    set ret3 [ regsub -nocase -all -- $ln $mALIAS $ln_new mALIAS_new ]
				if {$ret3>0} { 
				    #
			        $db2 "UPDATE SYS_APPL SET ALIAS='${mALIAS_new}' WHERE ID=$mID"
				    $db2 commit
				    #
			        LogWrite "SYS_APPL (ID=${mID}) old='${mALIAS}'  new='${mALIAS_new}' "
			    }
			}   
		   }		   
        }


       #--VS_COMP
       $db2 "UPDATE VS_COMP SET ID_FORM=$j WHERE ID_FORM=$maxID"
       $db2 commit
       #--VS_OBJ_TUNE  ++++++
       $db2 "UPDATE VS_OBJ_TUNE SET ID_FORM=$j WHERE ID_FORM=$maxID"
       $db2 commit
       #--VS_MODUS_NODE 
       $db2 "UPDATE VS_MODUS_NODE  SET ID_FORM=$j WHERE ID_FORM=$maxID"
       $db2 commit	 
       #--VS_FORM_INIPARAMS  
       $db2 "UPDATE VS_FORM_INIPARAMS   SET ID_FORM=$j WHERE ID_FORM=$maxID"
       $db2 commit		   
       
	   #--US_MENU  ID_APPL=1232 - schemeviewer.exe
       $db2 "UPDATE US_MENU SET ID_PARAM=$j WHERE ID_PARAM=$maxID AND ID_APPL=$ID_APPL"
       $db2 commit
       #--VP_PARAMS  ID_TABLE=43 - VS_FORM_LST
       $db2 "UPDATE VP_PARAMS SET ID_PARAM=$j WHERE ID_PARAM=$maxID AND ID_TABLE=$ID_TABLE"
       $db2 commit
       #--VS_REGIM_TUNE  ID_TABLE=43 - VS_FORM_LST
       $db2 "UPDATE VS_REGIM_TUNE SET ID_PARAM=$j WHERE ID_PARAM=$maxID AND ID_TABLE=$ID_TABLE"
       $db2 commit

      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE NAME LIKE '%TEXTRENAMETEXT%' "
    $db2 commit

    set strSQL3 "SELECT ${TABLE_NAME}_S.nextval FROM dual"
    set r3 [ $db2 $strSQL3 ]
    set l3 [ llength $r3 ]
    if {$l3>0} {
     set increment_old [lindex $r3 0 ]
     set increment_old [ expr (1-int($increment_old)) ]
     set str2 [ format "alter sequence %s_S increment by %d" $TABLE_NAME $increment_old ]
     $db2 $str2
     $db2 $strSQL3
     $db2 "alter sequence ${TABLE_NAME}_S increment by 1"
    }

  }

 return 0 ;
}



# ==============================================================================================================

# -- RPT_DIR
proc RPT_DIR { rf db2 } {

  set TABLE_LIST [ list RPT_DIR ]

  foreach TABLE_NAME $TABLE_LIST {

    set strSQL1 "SELECT max(ID), min(ID), count(*) FROM $TABLE_NAME"

    set maxID 0 ; set minID 0 ; set cntID 0 ;
    foreach {r1} [ $db2 $strSQL1 ] {
      set maxID [ lindex $r1 0 ]
      set minID [ lindex $r1 1 ]
      set cntID [ lindex $r1 2 ]
      set s1 "\n$TABLE_NAME = max=$maxID min=$minID cnt=$cntID \n"
      puts $s1
    }

    set maxID [ expr int($maxID)+1 ]
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_PARENT,ID_TYPE,NAME,ALIAS) VALUES ($maxID,NULL,1,'TEXTRENAMETEXT','') "
    $db2 $strSQL0
    $db2 commit


    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {
	  
	   LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

       #--RPT_DIR
       $db2 "UPDATE RPT_DIR SET ID_PARENT=$maxID WHERE ID_PARENT=$id_old"
       $db2 commit
       #--RPT_LST
       $db2 "UPDATE RPT_LST SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
       $db2 commit

       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

       #--RPT_LST
       $db2 "UPDATE RPT_LST SET ID_NODE=$j WHERE ID_NODE=$maxID"
       $db2 commit
       #--RPT_DIR
       $db2 "UPDATE RPT_DIR SET ID_PARENT=$j WHERE ID_PARENT=$maxID"
       $db2 commit

      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE NAME LIKE '%TEXTRENAMETEXT%' "
    $db2 commit

    set strSQL3 "SELECT ${TABLE_NAME}_S.nextval FROM dual"
    set r3 [ $db2 $strSQL3 ]
    set l3 [ llength $r3 ]
    if {$l3>0} {
     set increment_old [lindex $r3 0 ]
     set increment_old [ expr (1-int($increment_old)) ]
     set str2 [ format "alter sequence %s_S increment by %d" $TABLE_NAME $increment_old ]
     $db2 $str2
     $db2 $strSQL3
     $db2 "alter sequence ${TABLE_NAME}_S increment by 1"
    }

  }

 return 0 ;
}


#  -- RPT_LST  - необходимо проверить ID_TABLE=71 - RPT_LST , ID_APPL=964 - клиент просмотра отчетов
proc RPT_LST { rf db2 ID_TABLE ID_APPL } {

  set TABLE_LIST [ list RPT_LST ]

  foreach TABLE_NAME $TABLE_LIST {

    set strSQL1 "SELECT max(ID), min(ID), count(*) FROM $TABLE_NAME"

    set maxID 0 ; set minID 0 ; set cntID 0 ;
    foreach {r1} [ $db2 $strSQL1 ] {
      set maxID [ lindex $r1 0 ]
      set minID [ lindex $r1 1 ]
      set cntID [ lindex $r1 2 ]
      set s1 "\n$TABLE_NAME = max=$maxID min=$minID cnt=$cntID \n"
      puts $s1
    }

    set maxID [ expr int($maxID)+1 ]
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_NODE,NAME,ALIAS,NAME_RPT,ID_TYPE,UPDATE_SECONDS) VALUES ($maxID,NULL,'TEXTRENAMETEXT','','TEXTRENAMETEXT',510,1) "
    $db2 $strSQL0
    $db2 commit


    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {
	  
	   LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

       #--RPT_PARAMS
       $db2 "UPDATE RPT_PARAMS SET ID_REPORT=$maxID WHERE ID_REPORT=$id_old"
       $db2 commit

       #--US_MENU  ID_APPL=964 - клиент просмотра отчетов
       $db2 "UPDATE US_MENU SET ID_PARAM=$maxID WHERE ID_PARAM=$id_old AND ID_APPL=$ID_APPL"
       $db2 commit

       #--VP_PARAMS  ID_TABLE=71 - RPT_LST
       $db2 "UPDATE VP_PARAMS SET ID_PARAM=$maxID WHERE ID_PARAM=$id_old AND ID_TABLE=$ID_TABLE"
       $db2 commit

       #--VS_REGIM_TUNE  ID_TABLE=71 - RPT_LST
       $db2 "UPDATE VS_REGIM_TUNE SET ID_PARAM=$maxID WHERE ID_PARAM=$id_old AND ID_TABLE=$ID_TABLE"
       $db2 commit


       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit


       #--RPT_PARAMS
       $db2 "UPDATE RPT_PARAMS SET ID_REPORT=$j WHERE ID_REPORT=$maxID"
       $db2 commit

       #--US_MENU  ID_APPL=964 - клиент просмотра отчетов
       $db2 "UPDATE US_MENU SET ID_PARAM=$j WHERE ID_PARAM=$maxID AND ID_APPL=$ID_APPL"
       $db2 commit

       #--VP_PARAMS  ID_TABLE=71 - RPT_LST
       $db2 "UPDATE VP_PARAMS SET ID_PARAM=$j WHERE ID_PARAM=$maxID AND ID_TABLE=$ID_TABLE"
       $db2 commit

       #--VS_REGIM_TUNE  ID_TABLE=71 - RPT_LST
       $db2 "UPDATE VS_REGIM_TUNE SET ID_PARAM=$j WHERE ID_PARAM=$maxID AND ID_TABLE=$ID_TABLE"
       $db2 commit


      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE NAME LIKE '%TEXTRENAMETEXT%' "
    $db2 commit

    set strSQL3 "SELECT ${TABLE_NAME}_S.nextval FROM dual"
    set r3 [ $db2 $strSQL3 ]
    set l3 [ llength $r3 ]
    if {$l3>0} {
     set increment_old [lindex $r3 0 ]
     set increment_old [ expr (1-int($increment_old)) ]
     set str2 [ format "alter sequence %s_S increment by %d" $TABLE_NAME $increment_old ]
     $db2 $str2
     $db2 $strSQL3
     $db2 "alter sequence ${TABLE_NAME}_S increment by 1"
    }

  }

 return 0 ;
}

# ==============================================================================================================

# -- ARC_SUBSYST_PROFILE
proc ARC1 { rf db2 } {

  set TABLE_LIST [ list ARC_SUBSYST_PROFILE ]

  foreach TABLE_NAME $TABLE_LIST {

    set strSQL1 "SELECT max(ID), min(ID), count(*) FROM $TABLE_NAME"

    set maxID 0 ; set minID 0 ; set cntID 0 ;
    foreach {r1} [ $db2 $strSQL1 ] {
      set maxID [ lindex $r1 0 ]
      set minID [ lindex $r1 1 ]
      set cntID [ lindex $r1 2 ]
      set s1 "\n$TABLE_NAME = max=$maxID min=$minID cnt=$cntID \n"
      puts $s1
    }

    set maxID [ expr int($maxID)+1 ]
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_TBLLST,ID_GINFO,IS_WRITEON,STACK_NAME,LAST_UPDATE,IS_VIEWABLE) VALUES ($maxID,29,1,0,'MEAS_ARC_29_1',0,0) "
    $db2 $strSQL0
    $db2 commit

    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {
	  
	   LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

       #--ARC_SERVICES_TUNE
       $db2 "UPDATE ARC_SERVICES_TUNE SET ID_SPROFILE=$maxID WHERE ID_SPROFILE=$id_old"
       $db2 commit
       #--ARC_SERVICES_ACCESS
       $db2 "UPDATE ARC_SERVICES_ACCESS SET ID_SPROFILE=$maxID WHERE ID_SPROFILE=$id_old"
       $db2 commit

       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

       #--ARC_SERVICES_TUNE
       $db2 "UPDATE ARC_SERVICES_TUNE SET ID_SPROFILE=$j WHERE ID_SPROFILE=$maxID"
       $db2 commit
       #--ARC_SERVICES_ACCESS
       $db2 "UPDATE ARC_SERVICES_ACCESS SET ID_SPROFILE=$j WHERE ID_SPROFILE=$maxID"
       $db2 commit

      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE ID=$maxID"
    $db2 commit

    set strSQL3 "SELECT ${TABLE_NAME}_S.nextval FROM dual"
    set r3 [ $db2 $strSQL3 ]
    set l3 [ llength $r3 ]
    if {$l3>0} {
     set increment_old [lindex $r3 0 ]
     set increment_old [ expr (1-int($increment_old)) ]
     set str2 [ format "alter sequence %s_S increment by %d" $TABLE_NAME $increment_old ]
     $db2 $str2
     $db2 $strSQL3
     $db2 "alter sequence ${TABLE_NAME}_S increment by 1"
    }

  }

 return 0 ;
}

# ==============================================================================================================

proc AA2 { rf db2 } {

  set TABLE_LIST [ list J_AUSW J_PWSW J_USTCH J_ELSET J_DADV J_DAPARAMSTATE \
                        J_DA_SRC_VAL J_HWSTATE J_KVIT J_MEAS_SRC_VAL J_PHSET J_AUDIT \
            J_ARC_HIST_CLEAR ]
  #set TABLE_NAME [lindex $TABLE_LIST 0 ]

  foreach TABLE_NAME $TABLE_LIST {

    set strSQL1 "SELECT max(ID), min(ID), count(*) FROM $TABLE_NAME"

    set maxID 0 ; set minID 0 ; set cntID 0 ;
    foreach {r1} [ $db2 $strSQL1 ] {
      set maxID [ lindex $r1 0 ]
      set minID [ lindex $r1 1 ]
      set cntID [ lindex $r1 2 ]
      set s1 "\n$TABLE_NAME = max=$maxID min=$minID cnt=$cntID \n"
      puts $s1
    }

    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {
	  
	    LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"
		
        set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
        $db2 $strSQL3
        $db2 commit
      }
    }


##----alter sequence  J_RSDU_ERROR_S start with 1;
##--select J_RSDU_ERROR_S.nextval from dual -- 5
##--alter sequence J_RSDU_ERROR_S increment by -4;
##--select J_RSDU_ERROR_S.nextval from dual
##--alter sequence J_RSDU_ERROR_S increment by 1;

    set strSQL3 "SELECT ${TABLE_NAME}_S.nextval FROM dual"
    set r3 [ $db2 $strSQL3 ]
    set l3 [ llength $r3 ]
    if {$l3>0} {
     set increment_old [lindex $r3 0 ]
     set increment_old [ expr (1-int($increment_old)) ]
     set str2 [ format "alter sequence %s_S increment by %d" $TABLE_NAME $increment_old ]
     $db2 $str2
     $db2 $strSQL3
     $db2 "alter sequence ${TABLE_NAME}_S increment by 1"
    }

  }

 return 0 ;
}



# ==============================================================================================================

# -- DA_PARAM
proc DA_PARAM { rf db2 } {

    set TABLE_NAME "DA_PARAM"

    set strSQL1 "SELECT max(ID), min(ID), count(*) FROM $TABLE_NAME"

    set maxID 0 ; set minID 0 ; set cntID 0 ;
    foreach {r1} [ $db2 $strSQL1 ] {
      set maxID [ lindex $r1 0 ]
      set minID [ lindex $r1 1 ]
      set cntID [ lindex $r1 2 ]
      set s1 "\n$TABLE_NAME = max=$maxID min=$minID cnt=$cntID \n"
      puts $s1
    }

	LogWrite "============"
	set strSQL11 "SELECT * FROM $TABLE_NAME"
    foreach {r11} [ $db2 $strSQL11 ] {
      LogWrite $r11
    }
	LogWrite "============"

    set maxID [ expr int($maxID)+1 ]
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_NODE,ID_POINT,ID_UCLASS, PRIORITY, SCALE, SCALE_MAX, SCALE_MIN, NAME, ALIAS, STATE, APERTURE) VALUES ($maxID,1,1,1,0,1,1,1,'TEXTRENAMETEXT','',0,0) "
    $db2 $strSQL0
    $db2 commit

    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {
	  
	   LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"
	   # DA_ARC
	   # DA_PARGROUP_TUNE
	   # DA_PROFILE
	   # DA_SRC_CHANNEL
	   # DA_VAL
	   # J_MAILDISP
	   
	   # VP_PARAMS ID_TABLE ID_PARAM
	   # VS_REGIM_TUNE ID_TABLE ID_PARAM
	  
      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE NAME LIKE '%TEXTRENAMETEXT%' "
    $db2 commit

    set strSQL3 "SELECT ${TABLE_NAME}_S.nextval FROM dual"
    set r3 [ $db2 $strSQL3 ]
    set l3 [ llength $r3 ]
    if {$l3>0} {
     set increment_old [lindex $r3 0 ]
     set increment_old [ expr (1-int($increment_old)) ]
     set str2 [ format "alter sequence %s_S increment by %d" $TABLE_NAME $increment_old ]
     $db2 $str2
     $db2 $strSQL3
     $db2 "alter sequence ${TABLE_NAME}_S increment by 1"
    }


 return 0 ;
}

# ==============================================================================================================

# -- DA_DEV
proc DA_DEV { rf db2 } {

    set TABLE_NAME "DA_DEV"

    set strSQL1 "SELECT max(ID), min(ID), count(*) FROM $TABLE_NAME"

    set maxID 0 ; set minID 0 ; set cntID 0 ;
    foreach {r1} [ $db2 $strSQL1 ] {
      set maxID [ lindex $r1 0 ]
      set minID [ lindex $r1 1 ]
      set cntID [ lindex $r1 2 ]
      set s1 "\n$TABLE_NAME = max=$maxID min=$minID cnt=$cntID \n"
      puts $s1
    }

    set maxID [ expr int($maxID)+1 ]
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,NAME,IS_ROUTE) VALUES ($maxID,'TEXTRENAMETEXT',0) "
    $db2 $strSQL0
    $db2 commit

    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {
	  
	   LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"
	  
       #--DA_SLAVE  ID_DEV
       $db2 "UPDATE DA_SLAVE SET ID_DEV=$maxID WHERE ID_DEV=$id_old"
       $db2 commit
       #--DA_DEV_PROTO  ID_DEV
       $db2 "UPDATE DA_DEV_PROTO SET ID_DEV=$maxID WHERE ID_DEV=$id_old"
       $db2 commit
       #--DA_DEV_DESC  ID_DEV
       $db2 "UPDATE DA_DEV_DESC SET ID_DEV=$maxID WHERE ID_DEV=$id_old"
       $db2 commit

       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

       #--DA_SLAVE  ID_DEV
       $db2 "UPDATE DA_SLAVE SET ID_DEV=$j WHERE ID_DEV=$maxID"
       $db2 commit
       #--DA_DEV_PROTO  ID_DEV
       $db2 "UPDATE DA_DEV_PROTO SET ID_DEV=$j WHERE ID_DEV=$maxID"
       $db2 commit
       #--DA_DEV_DESC  ID_DEV
       $db2 "UPDATE DA_DEV_DESC SET ID_DEV=$j WHERE ID_DEV=$maxID"
       $db2 commit

      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE NAME LIKE '%TEXTRENAMETEXT%' "
    $db2 commit

    set strSQL3 "SELECT ${TABLE_NAME}_S.nextval FROM dual"
    set r3 [ $db2 $strSQL3 ]
    set l3 [ llength $r3 ]
    if {$l3>0} {
     set increment_old [lindex $r3 0 ]
     set increment_old [ expr (1-int($increment_old)) ]
     set str2 [ format "alter sequence %s_S increment by %d" $TABLE_NAME $increment_old ]
     $db2 $str2
     $db2 $strSQL3
     $db2 "alter sequence ${TABLE_NAME}_S increment by 1"
    }


 return 0 ;
}

# ==============================================================================================================

# -- DA_DEV_DESC
proc DA_DEV_DESC { rf db2 } {

    # -- DA_DEV_DESC  ID  ID_PARENT
    set TABLE_NAME "DA_DEV_DESC"

    set strSQL1 "SELECT max(ID), min(ID), count(*) FROM $TABLE_NAME"

    set maxID 0 ; set minID 0 ; set cntID 0 ;
    foreach {r1} [ $db2 $strSQL1 ] {
      set maxID [ lindex $r1 0 ]
      set minID [ lindex $r1 1 ]
      set cntID [ lindex $r1 2 ]
      set s1 "\n$TABLE_NAME = max=$maxID min=$minID cnt=$cntID \n"
      puts $s1
    }

    set maxID [ expr int($maxID)+1 ]
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_PROTO_POINT,ID_DEV,ID_PARENT,NAME,CVALIF,ID_TYPE,ID_GTOPT,ATTR_NAME,SCALE,COLOR) \
  VALUES ($maxID,51,1,$maxID,'TEXTRENAMETEXT',1,405,1,null,1,'')"
    $db2 $strSQL0
    $db2 commit

    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {
	  
	    LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

        #--DA_PARAM  ID_POINT
        $db2 "UPDATE DA_PARAM SET ID_POINT=$maxID WHERE ID_POINT=$id_old"
        $db2 commit

        #--  ID_PARENT
        $db2 "UPDATE $TABLE_NAME SET ID_PARENT=$maxID WHERE ID_PARENT=$id_old"
        $db2 commit


        $db2 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
        $db2 commit


        #--  ID_PARENT
        $db2 "UPDATE $TABLE_NAME SET ID_PARENT=$j WHERE ID_PARENT=$maxID"
        $db2 commit

        #--DA_PARAM  ID_POINT
        $db2 "UPDATE DA_PARAM SET ID_POINT=$j WHERE ID_POINT=$maxID"
        $db2 commit

      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE NAME LIKE '%TEXTRENAMETEXT%' "
    $db2 commit

    set strSQL3 "SELECT ${TABLE_NAME}_S.nextval FROM dual"
    set r3 [ $db2 $strSQL3 ]
    set l3 [ llength $r3 ]
    if {$l3>0} {
     set increment_old [lindex $r3 0 ]
     set increment_old [ expr (1-int($increment_old)) ]
     set str2 [ format "alter sequence %s_S increment by %d" $TABLE_NAME $increment_old ]
     $db2 $str2
     $db2 $strSQL3
     $db2 "alter sequence ${TABLE_NAME}_S increment by 1"
    }


 return 0 ;
}


# ==============================================================================================================

# -- DA_CAT -- отключать ssbsd + перестроить view da_v_cat_XXX     с новыми id
proc DA_CAT { rf db2 } {

    set TABLE_NAME "DA_CAT"

    set strSQL1 "SELECT max(ID), min(ID), count(*) FROM $TABLE_NAME"

    set maxID 0 ; set minID 0 ; set cntID 0 ;
    foreach {r1} [ $db2 $strSQL1 ] {
      set maxID [ lindex $r1 0 ]
      set minID [ lindex $r1 1 ]
      set cntID [ lindex $r1 2 ]
      set s1 "\n$TABLE_NAME = max=$maxID min=$minID cnt=$cntID \n"
      puts $s1
    }


    set strSQL1 "SELECT * FROM $TABLE_NAME ORDER BY ID ASC"
    foreach {r1} [ $db2 $strSQL1 ] {
      set s0 "$r1"
      LogWrite "$r1"
    }
	
	LogWrite "----------\n"
	#return ;

    set maxID [ expr int($maxID)+1 ]
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_TYPE,ID_PARENT,NAME,ALIAS,ID_RESERVE,ID_FILEWAV) VALUES ($maxID,1,NULL,'TEXTRENAMETEXT','',NULL,NULL) "
    $db2 $strSQL0
    $db2 commit

    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {
	  
	   LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"
	  
       #--DA_DEV_OPT  ID_NODE
       $db2 "UPDATE DA_DEV_OPT SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
       $db2 commit
       #--DA_EQUALIFIER  ID_NODE
       $db2 "UPDATE DA_EQUALIFIER SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
       $db2 commit 
       #--DA_FAILURE_JRNL  ID_NODE
       $db2 "UPDATE DA_FAILURE_JRNL SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
       $db2 commit 
       #--DA_KTSUSD  ID_NODE
       $db2 "UPDATE DA_KTSUSD SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
       $db2 commit 
       #--DA_MASTER  ID_NODE
       $db2 "UPDATE DA_MASTER SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
       $db2 commit 	   
       #--DA_PARAM  ID_NODE
       $db2 "UPDATE DA_PARAM SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
       $db2 commit 
       #--DA_PC  ID_NODE
       $db2 "UPDATE DA_PC SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
       $db2 commit 
       #--DA_PORT  ID_NODE
       $db2 "UPDATE DA_PORT SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
       $db2 commit
       #--DA_SLAVE  ID_NODE
       $db2 "UPDATE DA_SLAVE SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
       $db2 commit 

       #--J_DADV  ID_DEVICE
       $db2 "UPDATE J_DADV SET ID_DEVICE=$maxID WHERE ID_DEVICE=$id_old"
       $db2 commit 
       #--J_DAPARAMSTATE  ID_DEVICE
       $db2 "UPDATE J_DAPARAMSTATE SET ID_DEVICE=$maxID WHERE ID_DEVICE=$id_old"
       $db2 commit 
	   


       #--DA_CAT  ID_RESERVE
       $db2 "UPDATE $TABLE_NAME SET ID_RESERVE=$maxID WHERE ID_RESERVE=$id_old"
       $db2 commit 
       #--DA_CAT  ID_PARENT
       $db2 "UPDATE $TABLE_NAME SET ID_PARENT=$maxID WHERE ID_PARENT=$id_old"
       $db2 commit
	   
       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit
       
	   #--DA_CAT  ID_RESERVE
       $db2 "UPDATE $TABLE_NAME SET ID_RESERVE=$j WHERE ID_RESERVE=$maxID"
       $db2 commit 
       #--DA_CAT  ID_PARENT
       $db2 "UPDATE $TABLE_NAME SET ID_PARENT=$j WHERE ID_PARENT=$maxID"
       $db2 commit



       #--DA_DEV_OPT  ID_NODE
       $db2 "UPDATE DA_DEV_OPT SET ID_NODE=$j WHERE ID_NODE=$maxID"
       $db2 commit
       #--DA_EQUALIFIER  ID_NODE
       $db2 "UPDATE DA_EQUALIFIER SET ID_NODE=$j WHERE ID_NODE=$maxID"
       $db2 commit 
       #--DA_FAILURE_JRNL  ID_NODE
       $db2 "UPDATE DA_FAILURE_JRNL SET ID_NODE=$j WHERE ID_NODE=$maxID"
       $db2 commit 
       #--DA_KTSUSD  ID_NODE
       $db2 "UPDATE DA_KTSUSD SET ID_NODE=$j WHERE ID_NODE=$maxID"
       $db2 commit 
       #--DA_MASTER  ID_NODE
       $db2 "UPDATE DA_MASTER SET ID_NODE=$j WHERE ID_NODE=$maxID"
       $db2 commit 	   
       #--DA_PARAM  ID_NODE
       $db2 "UPDATE DA_PARAM SET ID_NODE=$j WHERE ID_NODE=$maxID"
       $db2 commit 
       #--DA_PC  ID_NODE
       $db2 "UPDATE DA_PC SET ID_NODE=$j WHERE ID_NODE=$maxID"
       $db2 commit 
       #--DA_PORT  ID_NODE
       $db2 "UPDATE DA_PORT SET ID_NODE=$j WHERE ID_NODE=$maxID"
       $db2 commit
       #--DA_SLAVE  ID_NODE
       $db2 "UPDATE DA_SLAVE SET ID_NODE=$j WHERE ID_NODE=$maxID"
       $db2 commit 

       #--J_DADV  ID_DEVICE
       $db2 "UPDATE J_DADV SET ID_DEVICE=$j WHERE ID_DEVICE=$maxID"
       $db2 commit 
       #--J_DAPARAMSTATE  ID_DEVICE
       $db2 "UPDATE J_DAPARAMSTATE SET ID_DEVICE=$j WHERE ID_DEVICE=$maxID"
       $db2 commit 

      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE NAME LIKE '%TEXTRENAMETEXT%' "
    $db2 commit

    set strSQL3 "SELECT ${TABLE_NAME}_S.nextval FROM dual"
    set r3 [ $db2 $strSQL3 ]
    set l3 [ llength $r3 ]
    if {$l3>0} {
     set increment_old [lindex $r3 0 ]
     set increment_old [ expr (1-int($increment_old)) ]
     set str2 [ format "alter sequence %s_S increment by %d" $TABLE_NAME $increment_old ]
     $db2 $str2
     $db2 $strSQL3
     $db2 "alter sequence ${TABLE_NAME}_S increment by 1"
    }


 return 0 ;
}


# ==============================================================================================================

proc CCC0 { rf db2 ind1 ind2 } {

        #--AST_LINK ID_OBJ
        if {[checkTable $rf $db2 "AST_LINK" "ID_OBJ"]} {
          $db2 "UPDATE AST_LINK SET ID_OBJ=$ind1 WHERE ID_OBJ=$ind2"
          $db2 commit
        }
        #--CALC_LIST  ID_NODE
        if {[checkTable $rf $db2 "CALC_LIST" "ID_NODE"]} {
          $db2 "UPDATE CALC_LIST SET ID_NODE=$ind1 WHERE ID_NODE=$ind2"
          $db2 commit
        }
        #--DG_GROUPS_DESC ID_OBJ
        if {[checkTable $rf $db2 "DG_GROUPS_DESC" "ID_OBJ" ]} {
          $db2 "UPDATE DG_GROUPS_DESC SET ID_OBJ=$ind1 WHERE ID_OBJ=$ind2"
          $db2 commit
        }
        #--EA_POINTS  ID_OBJ
        if {[checkTable $rf $db2 "EA_POINTS" "ID_OBJ"]} {
          $db2 "UPDATE EA_POINTS SET ID_OBJ=$ind1 WHERE ID_OBJ=$ind2"
          $db2 commit
        }

        #--FEED_PROP  ID_OBJ
        if {[checkTable $rf $db2 "FEED_PROP" "ID_OBJ_FEEDER"]} {
          $db2 "UPDATE FEED_PROP SET ID_OBJ_FEEDER=$ind1 WHERE ID_OBJ_FEEDER=$ind2"
          $db2 commit
        }

        #--NTP_EDGE  ID_OBJ
        if {[checkTable $rf $db2 "NTP_EDGE" "ID_OBJ"]} {
          $db2 "UPDATE NTP_EDGE SET ID_OBJ=$ind1 WHERE ID_OBJ=$ind2"
          $db2 commit
        }

        #--MEAS_LIST  ID_OBJ
        if {[checkTable $rf $db2 "MEAS_LIST" "ID_OBJ"]} {
          $db2 "UPDATE MEAS_LIST SET ID_OBJ=$ind1 WHERE ID_OBJ=$ind2"
          $db2 commit
        }


        #--J_ELSET ID_OBJECT
        if {[checkTable $rf $db2 "J_ELSET" "ID_OBJECT"]} {
          #LOCK TABLE J_ELSET IN SHARE ROW EXCLUSIVE MODE;
          $db2 "UPDATE J_ELSET SET ID_OBJECT=$ind1 WHERE ID_OBJECT=$ind2"
          $db2 commit
        }
        #--J_PHSET  ID_OBJECT
        if {[checkTable $rf $db2 "J_PHSET" "ID_OBJECT"]} {
          $db2 "UPDATE J_PHSET SET ID_OBJECT=$ind1 WHERE ID_OBJECT=$ind2"
          $db2 commit
        }
        #--J_TELEREG  ID_OBJECT
        if {[checkTable $rf $db2 "J_TELEREG" "ID_OBJECT"]} {
          $db2 "UPDATE J_TELEREG SET ID_OBJECT=$ind1 WHERE ID_OBJECT=$ind2"
          $db2 commit
        }

        #--J_TELEREG  ID_OBJECT
        #if {[checkTable $rf $db2 "J_TELEREG" "ID_OBJECT"]} {
        #  $db2 "UPDATE J_TELEREG SET ID_OBJECT=$ind1 WHERE ID_OBJECT=$ind2"
        #  $db2 commit
        #}


        #--OBJ_CNT  ID_OBJ
        if {[checkTable $rf $db2 "OBJ_CNT" "ID_OBJ"]} {
          $db2 "UPDATE OBJ_CNT SET ID_OBJ=$ind1 WHERE ID_OBJ=$ind2"
          $db2 commit
            }
        #--OBJ_EL_PIN  ID_OBJ
        if {[checkTable $rf $db2 "OBJ_EL_PIN" "ID_OBJ"]} {
          $db2 "UPDATE OBJ_EL_PIN SET ID_OBJ=$ind1 WHERE ID_OBJ=$ind2"
          $db2 commit
        }
        #--OBJ_LOCATION  ID_OBJ
        if {[checkTable $rf $db2 "OBJ_LOCATION" "ID_OBJ"]} {
          $db2 "UPDATE OBJ_LOCATION SET ID_OBJ=$ind1 WHERE ID_OBJ=$ind2"
          $db2 commit
        }
        #--OBJ_PARAM  ID_OBJ
        if {[checkTable $rf $db2 "OBJ_PARAM" "ID_OBJ"]} {
          $db2 "UPDATE OBJ_PARAM SET ID_OBJ=$ind1 WHERE ID_OBJ=$ind2"
          $db2 commit
        }

        #--OBJ_CONN_NODE  ID_OBJ
        if {[checkTable $rf $db2 "OBJ_CONN_NODE" "ID_OBJ"]} {
          $db2 "UPDATE OBJ_CONN_NODE SET ID_OBJ=$ind1 WHERE ID_OBJ=$ind2"
          $db2 commit
        }
        #--OBJ_GEO  ID_OBJ
        if {[checkTable $rf $db2 "OBJ_GEO" "ID_OBJ"]} {
          $db2 "UPDATE OBJ_GEO SET ID_OBJ=$ind1 WHERE ID_OBJ=$ind2"
          $db2 commit
        }
        #--OBJ_REFERENCES  ID_OBJ
        if {[checkTable $rf $db2 "OBJ_REFERENCES" "ID_OBJ"]} {
          $db2 "UPDATE OBJ_REFERENCES SET ID_OBJ=$ind1 WHERE ID_OBJ=$ind2"
          $db2 commit
        }

        #--TAG_LIST  ID_NODE
        if {[checkTable $rf $db2 "TAG_LIST" "ID_NODE"]} {
          $db2 "UPDATE TAG_LIST SET ID_NODE=$ind1 WHERE ID_NODE=$ind2"
          $db2 commit
        }


}



# -- OBJ_TREE -- !необходимо! гасить модули elregd, phregd, ?ssbsd?
proc OBJ_TREE { rf db2 } {

    set shiftID 0 ; # смещение id - нет , нельзя

    # -- OBJ_TREE  ID  ID_PARENT
    set TABLE_NAME "OBJ_TREE"

    set strSQL1 "SELECT max(ID), min(ID), count(*) FROM $TABLE_NAME"
    set maxID 0 ; set minID 0 ; set cntID 0 ;
    foreach {r1} [ $db2 $strSQL1 ] {
      set maxID [ lindex $r1 0 ]
      set minID [ lindex $r1 1 ]
      set cntID [ lindex $r1 2 ]
      set s1 "\n$TABLE_NAME => max=$maxID min=$minID cnt=$cntID \n"
      puts $s1
    }

    set maxID [ expr int($maxID)+1 + $shiftID ]
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_PARENT,ID_MODEL,ID_TYPE,ID_ORG,NAME,ALIAS,ID_FILEWAV,DATE_MOD,GUID) \
  VALUES ($maxID,null,null,5,null,'TEXTRENAMETEXT','TEXTRENAMETEXT',null,null,null)"
    $db2 $strSQL0
    $db2 commit

    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 + $shiftID ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {
	  
		LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

        CCC0 $rf $db2 $maxID $id_old

        if {[checkTable $rf $db2 $TABLE_NAME "ID" ]} {
          #-------  ID_PARENT
          $db2 "UPDATE $TABLE_NAME SET ID_PARENT=$maxID WHERE ID_PARENT=$id_old"
          $db2 commit
          $db2 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
          $db2 commit
          #--  ID_PARENT
          $db2 "UPDATE $TABLE_NAME SET ID_PARENT=$j WHERE ID_PARENT=$maxID"
          $db2 commit
        }

        CCC0 $rf $db2 $j $maxID

      }
    }

    puts "delete TEXTRENAMETEXT"
    $db2 "DELETE FROM $TABLE_NAME WHERE NAME LIKE '%TEXTRENAMETEXT%' "
    $db2 commit

    set strSQL3 "SELECT ${TABLE_NAME}_S.nextval FROM dual"
    set r3 [ $db2 $strSQL3 ]
    set l3 [ llength $r3 ]
    if {$l3>0} {
       set increment_old [lindex $r3 0 ]
       set increment_old [ expr (1-int($increment_old)) ]
       set str2 [ format "alter sequence %s_S increment by %d" $TABLE_NAME $increment_old ]
       $db2 $str2
       $db2 $strSQL3
       $db2 "alter sequence ${TABLE_NAME}_S increment by 1"
    }


 return 0 ;
}


# ==============================================================================================================


# -- одиночные таблицы
#BASE1 $rf db2


# -- SYS_APD
#SYS_APD  $rf db2
#
#SYS_APPL


# -- RPT_DIR
#RPT_DIR $rf db2
# -- RPT_LST   - необходимо проверить ID_TABLE=71 - RPT_LST , ID_APPL=964 - клиент просмотра отчетов
#RPT_LST $rf db2 71 964


# -- VS_GROUP
#VS_GROUP $rf db2
# -- VS_FORM  -  - необходимо проверить ID_TABLE=43 - VS_FORM_LST , ID_APPL=1232 - schemeviewer.exe
#VS_FORM $rf db2 43 1232


# -- VP_GROUP
#VP_GROUP $rf db2
# -- VP_PANEL - необходимо проверить ID_TABLE=40 - VP_PANEL , ID_APPL=87 - pnview.exe
#VP_PANEL $rf db2 40 87


# -- ARC_SUBSYST_PROFILE
#ARC1 $rf db2


# -- журналы -- отключать ssbsd
# AA2 $rf db2


# -- DA_PARAM
#DA_PARAM $rf db2

# -- DA_DEV
#DA_DEV $rf db2

# -- DA_DEV_DESC
#DA_DEV_DESC $rf db2

# -- DA_CAT -- отключать ssbsd + перестроить view с новыми id
#DA_CAT $rf db2


# -- OBJ_TREE -- отключать ssbsd + контроль Сигнальной системы  -- !необходимо! гасить модули elregd, phregd, ?ssbsd?
# #OBJ_TREE $rf db2


# ==============================================================================================================


  flush $rf

# ===============================================
# Закрываем соединение к БД
#  db2 commit
  db2 disconnect

  close $rf

  puts "-- End --"


