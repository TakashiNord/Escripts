#
#
#
#
#
#
#
#


package require tclodbc
package require sqlite3

set tns "rsdu2" ; #"rsdu2"  "RSDU_ATEC" "Postrsdu5" "poli24"
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
  #puts "-- $tblname  -- $df "
  if {$err!=""} { return 0 ; }
  return 1 ;
}


# ==============================================================================================================

# --
proc BASE1 { rf db2 } {

  set TABLE_LIST [ list AD_ACSRVC AD_SINFO_INI AD_JRNL \
 RSDU_UPDATE RSDU_ERROR \
 DA_SLAVE DA_MASTER DA_DEV_OPT DA_PC DA_PORT \
 MEAS_EL_DEPENDENT_SVAL \
 DBE_DESTINATION \
 DG_KDU_JOURNAL \
 R_PSETS \
 OBJ_GENERATOR_PQ \
 OBJ_MODEL_MEAS OBJ_PARAM OBJ_CONSTRAINT \
 OBJ_AUX_EL_PIN OBJ_LINK OBJ_LOCATION OBJ_MODEL_PARAM OBJ_PARAM \
 VP_PARAMS \
 SYS_APP_SERV_LST SYS_APP_SERVICES SYS_APP_SSYST SYS_APP_INI \
 SYS_OTYP_MEAS SYS_OTYP_PARAM \
 SYS_TBLREF SYS_TBLLNK \
 S_U_RGHT S_G_RGHT S_RIGHTS \
 SYS_UNIT \
 SIG_PROP \
 TAG_DOCS \
 US_ZONE US_VARS US_SIGN_PROP US_SIGN_GROUP US_SIG US_MSGLOG US_JSWITCH_FILTERS US_MAIL \
 VSZ_DICT ]


  set TABLE_LIST_3 [ list ]

  #set TABLE_LIST_5 [ list OBJ_MODEL_MEAS OBJ_PARAM ]

  foreach TABLE_NAME $TABLE_LIST {

    #--
    if {[checkTable $rf $db2 $TABLE_NAME "ID"]==0} {
        set s1 "\n$TABLE_NAME or ID = not exists"
        puts $s1
        continue
    }

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
    set err ""
    catch {
      set r3 [ $db2 $strSQL3 ]
      set p ""
    } err
    if {$err!=""} {
      LogWrite "$TABLE_NAME SELECT ${TABLE_NAME}_S.nextval FROM dual ( err=$err )"
      continue
    }

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


proc RSDU_UPDATE { rf db2 } {

  set TABLE_LIST [ list RSDU_UPDATE ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_PARENT,DT1970,STATE,NAME,DEFINE_ALIAS,SERVER_NAME,SCHEMA_NAME) VALUES ($maxID,NULL,0,0,'TEXTRENAMETEXT','TEXTRENAMETEXT','TEXTRENAMETEXT','RSDUADMIN') "
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

       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
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


proc SYS_TREE21 { rf db2 } {

  set TABLE_LIST [ list SYS_TREE21 ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_ICON,NAME) VALUES ($maxID,NULL,'TEXTRENAMETEXT') "
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

       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
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


proc DG_GROUPS { rf db2 } {

  set TABLE_LIST [ list DG_GROUPS ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_TYPE,NAME) VALUES ($maxID,1,'TEXTRENAMETEXT') "
    $db2 $strSQL0
    $db2 commit

    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

       #--DG_GROUPS_DESC
       $db2 "UPDATE DG_GROUPS_DESC SET ID_GROUP=$maxID WHERE ID_GROUP=$id_old"
       $db2 commit

       #--DG_KDU_JOURNAL
       $db2 "UPDATE DG_KDU_JOURNAL SET ID_OBJECT=$maxID WHERE ID_OBJECT=$id_old"
       $db2 commit


       if {[checkTable $rf $db2 "DG_KDU_JOURNAL_OLD" "ID_OBJECT"]} {
         #--DG_KDU_JOURNAL_OLD
         $db2 "UPDATE DG_KDU_JOURNAL_OLD SET ID_OBJECT=$maxID WHERE ID_OBJECT=$id_old"
         $db2 commit
       }

       #--DG_LIST
       $db2 "UPDATE DG_LIST SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
       $db2 commit


       #--$TABLE_NAME
       $db2 "UPDATE $TABLE_NAME SET ID_PARENT=$maxID WHERE ID_PARENT=$id_old"
       $db2 commit

       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

       #--$TABLE_NAME
       $db2 "UPDATE $TABLE_NAME SET ID_PARENT=$j WHERE ID_PARENT=$maxID"
       $db2 commit


       #--DG_GROUPS_DESC
       $db2 "UPDATE DG_GROUPS_DESC SET ID_GROUP=$j WHERE ID_GROUP=$maxID"
       $db2 commit

       #--DG_KDU_JOURNAL
       $db2 "UPDATE DG_KDU_JOURNAL SET ID_OBJECT=$j WHERE ID_OBJECT=$maxID"
       $db2 commit


       if {[checkTable $rf $db2 "DG_KDU_JOURNAL_OLD" "ID_OBJECT"]} {
         #--DG_KDU_JOURNAL_OLD
         $db2 "UPDATE DG_KDU_JOURNAL_OLD SET ID_OBJECT=$j WHERE ID_OBJECT=$maxID"
         $db2 commit
       }

     #--DG_LIST
       $db2 "UPDATE DG_LIST SET ID_NODE=$j WHERE ID_NODE=$maxID"
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

# -- S_GROUPS
proc S_GROUPS { rf db2 } {

  set TABLE_LIST [ list S_GROUPS ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_TYPE,NAME) VALUES ($maxID,1,'TEXTRENAMETEXT') "
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

       #--  ID_GROUP
       set TABLE_LIST [ list S_G_RGHT US_MENU US_SIG US_VARS ]
       foreach T_NAME $TABLE_LIST {
         $db2 "UPDATE $T_NAME SET ID_GROUP=$maxID WHERE ID_GROUP=$id_old"
         $db2 commit
       }

       #--S_USERS
       $db2 "UPDATE S_USERS SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
       $db2 commit


       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit


       #--  ID_GROUP
       set TABLE_LIST [ list S_G_RGHT US_MENU US_SIG US_VARS ]
       foreach T_NAME $TABLE_LIST {
         $db2 "UPDATE $T_NAME SET ID_GROUP=$j WHERE ID_GROUP=$maxID"
         $db2 commit
       }

       #--S_USERS
       $db2 "UPDATE S_USERS SET ID_NODE=$j WHERE ID_NODE=$maxID"
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


proc S_USERS_TABLE { rf db2 ind1 ind2 mode } {

  ##if {$mode!=0} {
    #--DB_S_USERS  S_ID
    if {[checkTable $rf $db2 "DB_S_USERS" "S_ID"]} {
      $db2 "UPDATE DB_S_USERS SET S_ID=$ind1 WHERE S_ID=$ind2"
      $db2 commit
    }
  ##}


  #--  ID_USER_CREATE ID_USER_MODIFY
  set TABLE_LIST [ list DG_KDU_JOURNAL  DG_KDU_JOURNAL_OLD TAG_LIST  ]
  foreach TABLE_NAME $TABLE_LIST {
    #--  ID_USER_CREATE ID_USER_MODIFY
    if {[checkTable $rf $db2 $TABLE_NAME "ID_USER_CREATE"]} {
      $db2 "UPDATE $TABLE_NAME SET ID_USER_CREATE=$ind1 WHERE ID_USER_CREATE=$ind2"
      $db2 commit
    }
    if {[checkTable $rf $db2 $TABLE_NAME "ID_USER_MODIFY"]} {
      $db2 "UPDATE $TABLE_NAME SET ID_USER_MODIFY=$ind1 WHERE ID_USER_MODIFY=$ind2"
      $db2 commit
    }
  }


  #--  ID_USER
  set TABLE_LIST [ list AD_SINFO  HG_NOTES \
   J_DA_SRC_VAl J_MEAS_SRC_VAL J_USER_AUDIT  J_USTCH \
   RSDU_USERS  S_U_RGHT  RSDU_PROCS \
   SYS_DIST \
   US_APPL_CONFIG  US_ENV US_MENU US_SIG US_SIGN  US_SIGN_GROUP US_SIGN_PROP  US_VARS  US_ZONE  ]

  foreach TABLE_NAME $TABLE_LIST {
    #--  ID_USER
    if {[checkTable $rf $db2 $TABLE_NAME "ID_USER"]} {
      $db2 "UPDATE $TABLE_NAME SET ID_USER=$ind1 WHERE ID_USER=$ind2"
      $db2 commit
    }
  }


  #--  ID_SRCUSER  ID_CAUSE
  set TABLE_LIST [ list J_ARC_VAL_CHANGE  J_AUSW  J_DADV  J_DAPARAMSTATE  J_DBE \
  J_DGSTATE  J_ELSET  J_ENMAC_EVENTS  J_HWSTATE J_KVIT  J_MAILDISP  J_PHSET \
  J_PSTATE  J_PWSW ]
  foreach TABLE_NAME $TABLE_LIST {
    #--  ID_SRCUSER  ID_CAUSE
    if {[checkTable $rf $db2 $TABLE_NAME "ID_SRCUSER"]} {
      $db2 "UPDATE $TABLE_NAME SET ID_SRCUSER=$ind1 WHERE ID_SRCUSER=$ind2"
      $db2 commit
    }
    if {[checkTable $rf $db2 $TABLE_NAME "ID_CAUSE"]} {
      $db2 "UPDATE $TABLE_NAME SET ID_CAUSE=$ind1 WHERE ID_CAUSE=$ind2"
      $db2 commit
    }
  }


  #--US_MAIL  ID_USER ID_USER_DST
  set TABLE_LIST [ list US_MAIL  US_MSGLOG ]
  foreach TABLE_NAME $TABLE_LIST {
    #--  ID_USER ID_USER_DST
    if {[checkTable $rf $db2 $TABLE_NAME "ID_USER"]} {
      $db2 "UPDATE $TABLE_NAME SET ID_USER=$ind1 WHERE ID_USER=$ind2"
      $db2 commit
    }
    if {[checkTable $rf $db2 $TABLE_NAME "ID_USER_DST"]} {
      $db2 "UPDATE $TABLE_NAME SET ID_USER_DST=$ind1 WHERE ID_USER_DST=$ind2"
      $db2 commit
    }
  }


  #--WSERV_UMENU  R_UID
  if {[checkTable $rf $db2 "WSERV_UMENU" "R_UID"]} {
    $db2 "UPDATE WSERV_UMENU SET R_UID=$ind1 WHERE R_UID=$ind2"
    $db2 commit
  }

  #--RSDUJOB.JOB_MAIN  ID_USER_EXECUTE  ID_USER_CREATE
  if {[checkTable $rf $db2 "RSDUJOB.JOB_MAIN" "ID_USER_EXECUTE"]} {
    $db2 "UPDATE RSDUJOB.JOB_MAIN SET ID_USER_EXECUTE=$ind1 WHERE ID_USER_EXECUTE=$ind2"
    $db2 commit
  }
  if {[checkTable $rf $db2 "RSDUJOB.JOB_MAIN" "ID_USER_CREATE"]} {
    $db2 "UPDATE RSDUJOB.JOB_MAIN SET ID_USER_CREATE=$ind1 WHERE ID_USER_CREATE=$ind2"
    $db2 commit
  }


}

# -- S_USERS
proc S_USERS { rf db2 } {

  set TABLE_LIST [ list S_USERS ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_NODE,ID_TYPE,LOGIN,NAME) VALUES ($maxID,1,1,'TEXTX1','TEXTX1') "
    $db2 $strSQL0
    $db2 commit

    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {
        LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"
        S_USERS_TABLE $rf $db2 $maxID $id_old 1
        if {[checkTable $rf $db2 $TABLE_NAME "ID" ]} {
          set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
          $db2 $strSQL3
          $db2 commit
        }
        S_USERS_TABLE $rf $db2 $j $maxID 1
      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE NAME LIKE '%TEXTX1%' "
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


# -- S_USERS=DB_S_USERS
proc S_USERS__DB_S_USERS { rf db2 } {

  # -- переводим id в последовательность 1....n
  S_USERS $rf $db2

  return ;
  --------------------------------------------------------

 return 0 ;
}


# ==============================================================================================================

# -- US_BUTTON_DESC
proc US_BUTTON_DESC { rf db2 } {

  set TABLE_LIST [ list US_BUTTON_DESC ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_TABLE,DEFINE_ALIAS,NAME,DESCRIPTION) VALUES ($maxID,7,'TEXTRENAMETEXT','TEXTRENAMETEXT','TEXTRENAMETEXT') "
    $db2 $strSQL0
    $db2 commit


    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

       #--US_MENU
       $db2 "UPDATE US_MENU SET ID_BUTTON=$maxID WHERE ID_BUTTON=$id_old"
       $db2 commit

       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

       #--US_MENU
       $db2 "UPDATE US_MENU SET ID_BUTTON=$j WHERE ID_BUTTON=$maxID"
       $db2 commit

      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE NAME LIKE '%TEXTRENAMETEXT%' "
    $db2 commit

  }

 return 0 ;
}

# -- US_MENU
proc US_MENU { rf db2 } {

  set TABLE_LIST [ list US_MENU ]

  foreach TABLE_NAME $TABLE_LIST {

    set strSQL1 "SELECT max(ID), min(ID), count(*) FROM $TABLE_NAME"

    set strSQL0 "DELETE FROM $TABLE_NAME WHERE ID_USER is null "
    $db2 $strSQL0
    $db2 commit

    set maxID 0 ; set minID 0 ; set cntID 0 ;
    foreach {r1} [ $db2 $strSQL1 ] {
      set maxID [ lindex $r1 0 ]
      set minID [ lindex $r1 1 ]
      set cntID [ lindex $r1 2 ]
      set s1 "\n$TABLE_NAME = max=$maxID min=$minID cnt=$cntID \n"
      puts $s1
    }

    # ---------------------------------------- ID_BUTTON
    set maxID [ expr int($maxID)+1 ]
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_BUTTON,NAME) VALUES ($maxID,37006,'TEXTRENAMETEXT') "
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

       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
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


# -- SYS_APPL
proc SYS_APPL { rf db2 } {

  set TABLE_LIST [ list SYS_APPL ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_NODE,NAME,ALIAS,ID_TYPE) VALUES ($maxID,NULL,'TEXTRENAMETEXT','',1) "
    $db2 $strSQL0
    $db2 commit


    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    set shift 1500
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old<$shift} { continue ; }
      set j_shift [ expr ($j+$shift) ]
      if {$id_old!=$j_shift} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j_shift ( maxID=$maxID )"

       #--  ID_APPL
       set TABLE_LIST2 [ list AD_DTYP AD_SINFO \
        AST_CTYP AST_DTYP AST_TTYP \
        DA_TYPE RSDU_SUBSYST S_TGRPS \
        SYS_APP_INI SYS_APP_PARAMS SYS_APP_SERVICES SYS_APP_SERV_LST SYS_APP_SSYST SYS_APP_TYPE SYS_DB_DTYP SYS_SRTT \
        US_APPL_CONFIG  US_ENV US_MENU US_VAR_DESC WPORTAL_MENU ]

       foreach TABLE_NAME2 $TABLE_LIST2 {
         #--  ID_APPL
         if {[checkTable $rf $db2 $TABLE_NAME2 "ID_APPL"]} {
           $db2 "UPDATE $TABLE_NAME2 SET ID_APPL=$maxID WHERE ID_APPL=$id_old"
           $db2 commit
         }
       }


       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j_shift WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit


       foreach TABLE_NAME2 $TABLE_LIST2 {
         #--  ID_APPL
         if {[checkTable $rf $db2 $TABLE_NAME2 "ID_APPL"]} {
           $db2 "UPDATE $TABLE_NAME2 SET ID_APPL=$j_shift WHERE ID_APPL=$maxID"
           $db2 commit
         }
       }


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


# -- AD_DIR
proc AD_DIR { rf db2 } {

  set TABLE_LIST [ list AD_DIR ]

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


       #--AD_HOSTS
       $db2 "UPDATE AD_HOSTS SET ID_SYSTEM_NODE=$maxID WHERE ID_SYSTEM_NODE=$id_old"
       $db2 commit
       $db2 "UPDATE AD_HOSTS SET ID_HOST_NODE=$maxID WHERE ID_HOST_NODE=$id_old"
       $db2 commit
       #--AD_PINFO
       $db2 "UPDATE AD_PINFO SET ID_INTRFACE_NODE=$maxID WHERE ID_INTRFACE_NODE=$id_old"
       $db2 commit
       #--AD_SEGMENT
       $db2 "UPDATE AD_SEGMENT SET ID_PORT_NODE=$maxID WHERE ID_PORT_NODE=$id_old"
       $db2 commit
       #--  ID_SERVER_NODE
       set TABLE_LIST [ list AD_JRNL AD_SINFO AD_SINFO_INI ]
       foreach T_NAME $TABLE_LIST {
         $db2 "UPDATE $T_NAME SET ID_SERVER_NODE=$maxID WHERE ID_SERVER_NODE=$id_old"
         $db2 commit
       }
       #--  ID_NODE
       set TABLE_LIST [ list AD_COMCARD AD_IPINFO AD_LIST AD_MBII AD_MODEM AD_NCARD \
        AD_PORT AD_SEGMENT ]
       foreach T_NAME $TABLE_LIST {
         $db2 "UPDATE $T_NAME SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
         $db2 commit
       }
       #--J_SHDV
       if {[checkTable $rf $db2 "J_SHDV" "ID_DEVICE"]} {
         $db2 "UPDATE J_SHDV SET ID_DEVICE=$maxID WHERE ID_DEVICE=$id_old"
         $db2 commit
       }


       #--AD_DIR
       $db2 "UPDATE AD_DIR SET ID_PARENT=$maxID WHERE ID_PARENT=$id_old"
       $db2 commit


       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit


       #--AD_DIR
       $db2 "UPDATE AD_DIR SET ID_PARENT=$j WHERE ID_PARENT=$maxID"
       $db2 commit


       #--J_SHDV
       if {[checkTable $rf $db2 "J_SHDV" "ID_DEVICE"]} {
         $db2 "UPDATE J_SHDV SET ID_DEVICE=$j WHERE ID_DEVICE=$maxID"
         $db2 commit
       }
       #--  ID_NODE
       set TABLE_LIST [ list AD_COMCARD AD_IPINFO AD_LIST AD_MBII AD_MODEM AD_NCARD \
        AD_PORT AD_SEGMENT ]
       foreach T_NAME $TABLE_LIST {
         $db2 "UPDATE $T_NAME SET ID_NODE=$j WHERE ID_NODE=$maxID"
         $db2 commit
       }
       #--  ID_SERVER_NODE
       set TABLE_LIST [ list AD_JRNL AD_SINFO AD_SINFO_INI ]
       foreach T_NAME $TABLE_LIST {
         $db2 "UPDATE $T_NAME SET ID_SERVER_NODE=$j WHERE ID_SERVER_NODE=$maxID"
         $db2 commit
       }
       #--AD_HOSTS
       $db2 "UPDATE AD_HOSTS SET ID_SYSTEM_NODE=$j WHERE ID_SYSTEM_NODE=$maxID"
       $db2 commit
       $db2 "UPDATE AD_HOSTS SET ID_HOST_NODE=$j WHERE ID_HOST_NODE=$maxID"
       $db2 commit
       #--AD_PINFO
       $db2 "UPDATE AD_PINFO SET ID_INTRFACE_NODE=$j WHERE ID_INTRFACE_NODE=$maxID"
       $db2 commit
       #--AD_SEGMENT
       $db2 "UPDATE AD_SEGMENT SET ID_PORT_NODE=$j WHERE ID_PORT_NODE=$maxID"
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



# -- AD_DTYP
proc AD_DTYP { rf db2 } {

  set TABLE_LIST [ list AD_DTYP ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,NAME) VALUES ($maxID,'TEXTRENAMETEXT') "
    $db2 $strSQL0
    $db2 commit

    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

       #--AD_DIR
       $db2 "UPDATE AD_DIR SET ID_TYPE=$maxID WHERE ID_TYPE=$id_old"
       $db2 commit


       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit


       #--AD_DIR
       $db2 "UPDATE AD_DIR SET ID_TYPE=$j WHERE ID_TYPE=$maxID"
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


# -- AD_LIST
proc AD_LIST { rf db2 } {

  set TABLE_LIST [ list AD_LIST ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_NODE,NAME,ALIAS,ID_TYPE) VALUES ($maxID,1,'TEXTRENAMETEXT','',1) "
    $db2 $strSQL0
    $db2 commit


    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

       #--AD_PINFO
       $db2 "UPDATE AD_PINFO SET ID_PARAM=$maxID WHERE ID_PARAM=$id_old"
       $db2 commit


       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit


       #--AD_PINFO
       $db2 "UPDATE AD_PINFO SET ID_PARAM=$j WHERE ID_PARAM=$maxID"
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

# -- AST_ORG
proc AST_ORG { rf db2 } {

  set TABLE_LIST [ list AST_ORG ]

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

       set TABLE_LIST [ list AST_LINK OBJ_TREE RSDU_USERS FEED_ORG_LINK ]
       foreach T_NAME $TABLE_LIST {
         #--
         if {[checkTable $rf $db2 $T_NAME "ID_ORG"]==0} {
          continue
         }
         $db2 "UPDATE $T_NAME SET ID_ORG=$maxID WHERE ID_ORG=$id_old"
         $db2 commit
       }
       #--AST_PERSONNEL
       $db2 "UPDATE AST_PERSONNEL SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
       $db2 commit



       #--AST_ORG
       $db2 "UPDATE AST_ORG SET ID_PARENT=$maxID WHERE ID_PARENT=$id_old"
       $db2 commit

       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

       #--AST_ORG
       $db2 "UPDATE AST_ORG SET ID_PARENT=$j WHERE ID_PARENT=$maxID"
       $db2 commit



       #--AST_PERSONNEL
       $db2 "UPDATE AST_PERSONNEL SET ID_NODE=$j WHERE ID_NODE=$maxID"
       $db2 commit
       set TABLE_LIST [ list AST_LINK  OBJ_TREE RSDU_USERS FEED_ORG_LINK ]
       foreach T_NAME $TABLE_LIST {
         #--
         if {[checkTable $rf $db2 $T_NAME "ID_ORG"]==0} {
          continue
         }
         $db2 "UPDATE $T_NAME SET ID_ORG=$j WHERE ID_ORG=$maxID"
         $db2 commit
       }

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


# -- AST_CNT
proc AST_CNT { rf db2 } {

  set TABLE_LIST [ list AST_CNT]

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

       #--AST_LINK
       $db2 "UPDATE AST_LINK SET ID_CNT=$maxID WHERE ID_CNT=$id_old"
       $db2 commit
       #--AST_CNT_LIST
       $db2 "UPDATE AST_CNT_LIST SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
       $db2 commit
       #--OBJ_CNT
       $db2 "UPDATE OBJ_CNT SET ID_CNT=$maxID WHERE ID_CNT=$id_old"
       $db2 commit
       #--DG_KDU_JOURNAL
       $db2 "UPDATE DG_KDU_JOURNAL SET ID_SRC_CNT=$maxID WHERE ID_SRC_CNT=$id_old"
       $db2 commit
       #--DG_KDU_JOURNAL_OLD
       if {[checkTable $rf $db2 "DG_KDU_JOURNAL_OLD" "ID_SRC_CNT"]} {
         $db2 "UPDATE DG_KDU_JOURNAL_OLD SET ID_SRC_CNT=$maxID WHERE ID_SRC_CNT=$id_old"
         $db2 commit
       }



       #--AST_CNT
       $db2 "UPDATE AST_CNT SET ID_PARENT=$maxID WHERE ID_PARENT=$id_old"
       $db2 commit

       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

       #--AST_CNT
       $db2 "UPDATE AST_CNT SET ID_PARENT=$j WHERE ID_PARENT=$maxID"
       $db2 commit



       #--AST_LINK
       $db2 "UPDATE AST_LINK SET ID_CNT=$j WHERE ID_CNT=$maxID"
       $db2 commit
       #--AST_CNT_LIST
       $db2 "UPDATE AST_CNT_LIST SET ID_NODE=$j WHERE ID_NODE=$maxID"
       $db2 commit
       #--OBJ_CNT
       $db2 "UPDATE OBJ_CNT SET ID_CNT=$j WHERE ID_CNT=$maxID"
       $db2 commit
       #--DG_KDU_JOURNAL
       $db2 "UPDATE DG_KDU_JOURNAL SET ID_SRC_CNT=$j WHERE ID_SRC_CNT=$maxID"
       $db2 commit
       #--DG_KDU_JOURNAL_OLD
       if {[checkTable $rf $db2 "DG_KDU_JOURNAL_OLD" "ID_SRC_CNT"]} {
         $db2 "UPDATE DG_KDU_JOURNAL_OLD SET ID_SRC_CNT=$j WHERE ID_SRC_CNT=$maxID"
         $db2 commit
       }

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



proc VP_CTRL { rf db2 } {

  set TABLE_LIST [ list VP_CTRL ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_PANEL,ID_TCTRL,CONST_NAME,FEATURE) VALUES ($maxID,1,1,'TEXTRENAMETEXT',0) "
    $db2 $strSQL0
    $db2 commit


    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

       #--VP_PARAMS
       $db2 "UPDATE VP_PARAMS SET ID_CTRL=$maxID WHERE ID_CTRL=$id_old"
       $db2 commit

       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

       #--VP_PARAMS
       $db2 "UPDATE VP_PARAMS SET ID_CTRL=$j WHERE ID_CTRL=$maxID"
       $db2 commit

      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE CONST_NAME LIKE '%TEXTRENAMETEXT%' "
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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_NODE,ID_TYPE,NAME,ALIAS,FILE_NAME,LAST_UPDATE,LAST_ACCESS) VALUES ($maxID,1,520,'TEXTRENAMETEXT','','TEXTRENAMETEXT',0,0) "
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
       #$db2 "UPDATE VS_OBJ_TUNE SET ID_FORM=$maxID WHERE ID_FORM=$id_old"
       #$db2 commit
       #--VS_MODUS_NODE
       if {[checkTable $rf $db2 "VS_MODUS_NODE" "ID_FORM"]} {
         $db2 "UPDATE VS_MODUS_NODE  SET ID_FORM=$maxID WHERE ID_FORM=$id_old"
         $db2 commit
       }
       #--VS_FORM_INIPARAMS
       if {[checkTable $rf $db2 "VS_FORM_INIPARAMS" "ID_FORM"]} {
         $db2 "UPDATE VS_FORM_INIPARAMS   SET ID_FORM=$maxID WHERE ID_FORM=$id_old"
         $db2 commit
       }
       #--TAG_POSITION
       $db2 "UPDATE TAG_POSITION   SET ID_SCHEME=$maxID WHERE ID_SCHEME=$id_old"
       $db2 commit
       #RSDUJOB.JOB_MAIN    ID_SCHEME
       $db2 "UPDATE RSDUJOB.JOB_MAIN   SET ID_SCHEME=$maxID WHERE ID_SCHEME=$id_old"
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
       #$db2 "UPDATE VS_OBJ_TUNE SET ID_FORM=$j WHERE ID_FORM=$maxID"
       #$db2 commit
       #--VS_MODUS_NODE
       if {[checkTable $rf $db2 "VS_MODUS_NODE" "ID_FORM"]} {
         $db2 "UPDATE VS_MODUS_NODE  SET ID_FORM=$j WHERE ID_FORM=$maxID"
         $db2 commit
       }
       #--VS_FORM_INIPARAMS
       if {[checkTable $rf $db2 "VS_FORM_INIPARAMS" "ID_FORM"]} {
         $db2 "UPDATE VS_FORM_INIPARAMS   SET ID_FORM=$j WHERE ID_FORM=$maxID"
         $db2 commit
       }
       #--TAG_POSITION
       $db2 "UPDATE TAG_POSITION   SET ID_SCHEME=$j WHERE ID_SCHEME=$maxID"
       $db2 commit
       #RSDUJOB.JOB_MAIN    ID_SCHEME
       $db2 "UPDATE RSDUJOB.JOB_MAIN   SET ID_SCHEME=$j WHERE ID_SCHEME=$maxID"
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


#  -- VS_COMP  -
proc VS_COMP { rf db2 } {

  set TABLE_LIST [ list VS_COMP ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_FORM,NAME,ID_TCTRL,FEATURE,PRECISION) VALUES ($maxID,1,'TEXTRENAMETEXT',1,0,0) "
    $db2 $strSQL0
    $db2 commit

    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

       #--VS_REGIM_TUNE
       $db2 "UPDATE VS_REGIM_TUNE SET ID_OWNLST=$maxID WHERE ID_OWNLST=$id_old"
       $db2 commit
       #--TAG_POSITION
       $db2 "UPDATE TAG_POSITION   SET ID_COMP=$maxID WHERE ID_COMP=$id_old"
       $db2 commit


       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit


       #--VS_REGIM_TUNE
       $db2 "UPDATE VS_REGIM_TUNE SET ID_OWNLST=$j WHERE ID_OWNLST=$maxID"
       $db2 commit
       #--TAG_POSITION
       $db2 "UPDATE TAG_POSITION   SET ID_COMP=$j WHERE ID_COMP=$maxID"
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

       #--ID_TABLE=71 - RPT_LST
     set TABLE_LIST [ list VP_PARAMS VS_REGIM_TUNE ]
       foreach T_NAME $TABLE_LIST {
         $db2 "UPDATE $T_NAME SET ID_PARAM=$maxID WHERE ID_PARAM=$id_old AND ID_TABLE=$ID_TABLE"
         $db2 commit
       }


       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit


       #--RPT_PARAMS
       $db2 "UPDATE RPT_PARAMS SET ID_REPORT=$j WHERE ID_REPORT=$maxID"
       $db2 commit

       #--US_MENU  ID_APPL=964 - клиент просмотра отчетов
       $db2 "UPDATE US_MENU SET ID_PARAM=$j WHERE ID_PARAM=$maxID AND ID_APPL=$ID_APPL"
       $db2 commit

       #--ID_TABLE=71 - RPT_LST
     set TABLE_LIST [ list VP_PARAMS VS_REGIM_TUNE ]
       foreach T_NAME $TABLE_LIST {
         $db2 "UPDATE $T_NAME SET ID_PARAM=$j WHERE ID_PARAM=$maxID AND ID_TABLE=$ID_TABLE"
         $db2 commit
       }

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
# -- R_GROUP
proc R_GROUP { rf db2 } {

  set TABLE_LIST [ list R_GROUP ]

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

       #--R_GROUP
       $db2 "UPDATE R_GROUP SET ID_PARENT=$maxID WHERE ID_PARENT=$id_old"
       $db2 commit
       #--R_KADR
       $db2 "UPDATE R_KADR SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
       $db2 commit

       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

       #--R_KADR
       $db2 "UPDATE R_KADR SET ID_NODE=$j WHERE ID_NODE=$maxID"
       $db2 commit
       #--R_GROUP
       $db2 "UPDATE R_GROUP SET ID_PARENT=$j WHERE ID_PARENT=$maxID"
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


#  -- R_KADR  - необходимо проверить ID_TABLE=46 - R_KADR , ID_APPL=602 - retroview_live.exe
proc R_KADR { rf db2 ID_TABLE ID_APPL } {

  set TABLE_LIST [ list R_KADR ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_NODE,ID_TYPE,NAME,ALIAS) VALUES ($maxID,NULL,526,'TEXTRENAMETEXT','') "
    if {[checkTable $rf $db2 $TABLE_NAME "SETTINGS_JSON"]} {
        set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_NODE,ID_TYPE,NAME,ALIAS,SETTINGS_JSON) VALUES ($maxID,NULL,526,'TEXTRENAMETEXT','','') "
    }

    $db2 $strSQL0
    $db2 commit


    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

       #--R_PSETS
       $db2 "UPDATE R_PSETS SET ID_KADR=$maxID WHERE ID_KADR=$id_old"
       $db2 commit


       #--US_MENU  ID_APPL=602 - retroview_live.exe
       $db2 "UPDATE US_MENU SET ID_PARAM=$maxID WHERE ID_PARAM=$id_old AND ID_APPL=$ID_APPL"
       $db2 commit
       #--VP_PARAMS  ID_TABLE=46 - R_KADR
       $db2 "UPDATE VP_PARAMS SET ID_PARAM=$maxID WHERE ID_PARAM=$id_old AND ID_TABLE=$ID_TABLE"
       $db2 commit
       #--VS_REGIM_TUNE  ID_TABLE=46 - R_KADR
       $db2 "UPDATE VS_REGIM_TUNE SET ID_PARAM=$maxID WHERE ID_PARAM=$id_old AND ID_TABLE=$ID_TABLE"
       $db2 commit


       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

       #SYS_APPL ( ALIAS )
       # retroview_live.exe /168
       set strSQL9 "SELECT ID, ALIAS FROM SYS_APPL"
       set r9all [ $db2 $strSQL9 ]
       foreach {r9} $r9all {
         set mID [ lindex $r9 0 ]
         set mALIAS [ lindex $r9 1 ]
         set ret1 [ regexp -nocase -- "retroview_live" $mALIAS ]
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


       #--R_PSETS
       $db2 "UPDATE R_PSETS SET ID_KADR=$j WHERE ID_KADR=$maxID"
       $db2 commit


       #--US_MENU  ID_APPL=602 - retroview_live.exe
       $db2 "UPDATE US_MENU SET ID_PARAM=$j WHERE ID_PARAM=$maxID AND ID_APPL=$ID_APPL"
       $db2 commit
       #--VP_PARAMS  ID_TABLE=46 - R_KADR
       $db2 "UPDATE VP_PARAMS SET ID_PARAM=$j WHERE ID_PARAM=$maxID AND ID_TABLE=$ID_TABLE"
       $db2 commit
       #--VS_REGIM_TUNE  ID_TABLE=46 - R_KADR
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

# -- DBE_STORAGE
proc DBE_STORAGE { rf db2 } {

  set TABLE_LIST [ list DBE_STORAGE ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,IS_ENABLED,NAME,ALIAS,CONNECTION_STRING,MAX_NUMBER_PARALLEL_JOBS) VALUES ($maxID,0,'TEXTRENAMETEXT','--','--',3) "
    $db2 $strSQL0
    $db2 commit

    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

       #--DBE_JOB
       $db2 "UPDATE DBE_JOB SET ID_STORAGE=$maxID WHERE ID_STORAGE=$id_old"
       $db2 commit

       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

       #--DBE_JOB
       $db2 "UPDATE DBE_JOB SET ID_STORAGE=$j WHERE ID_STORAGE=$maxID"
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

# -- DBE_JOB  -- J_DBE
proc DBE_JOB { rf db2 } {

  set TABLE_LIST [ list DBE_JOB ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_STORAGE,IS_ENABLED,NAME,ALIAS,SCHEDULE_CRON_EXPRESSION,\
  ID_TIMEINTERVAL,TIMEINTERVAL_COUNT,TIMEINTERVAL_OFFSET,RUN_TIME_OFFSET) \
  VALUES ($maxID,1,0,'TEXTRENAMETEXT','--','--',1,0,0,0) "
    $db2 $strSQL0
    $db2 commit

    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

       #--DBE_ACTION
       $db2 "UPDATE DBE_ACTION SET ID_JOB=$maxID WHERE ID_JOB=$id_old"
       $db2 commit

       #--J_DBE
       $db2 "UPDATE J_DBE SET ID_JOB=$maxID WHERE ID_JOB=$id_old"
       $db2 commit

       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

       #--DBE_ACTION
       $db2 "UPDATE DBE_ACTION SET ID_JOB=$j WHERE ID_JOB=$maxID"
       $db2 commit

       #--J_DBE
       $db2 "UPDATE J_DBE SET ID_JOB=$j WHERE ID_JOB=$maxID"
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


# -- DBE_ACTION  -- J_DBE
#DBE_ACTION $rf db2
proc DBE_ACTION { rf db2 } {

  set TABLE_LIST [ list DBE_ACTION ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_JOB,NAME,ALIAS,SQL_TEXT,\
  REQUEST_TIME_OFFSET,RESPONSE_TIME_OFFSET,ID_DTFIELD_TYPE,\
  ENABLE_ROW_HANDLER,ROW_HANDLER_TEXT,ENABLE_TABLE_HANDLER,TABLE_HANDLER_TEXT) \
  VALUES ($maxID,1,'TEXTRENAMETEXT','--','--',0,0,2,0,0,'',0,'') "
    $db2 $strSQL0
    $db2 commit

    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

       #--DBE_DESTINATION
       $db2 "UPDATE DBE_DESTINATION SET ID_ACTION=$maxID WHERE ID_ACTION=$id_old"
       $db2 commit

       #--J_DBE
       $db2 "UPDATE J_DBE SET ID_ACTION=$maxID WHERE ID_ACTION=$id_old"
       $db2 commit

       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

       #--DBE_DESTINATION
       $db2 "UPDATE DBE_DESTINATION SET ID_ACTION=$j WHERE ID_ACTION=$maxID"
       $db2 commit

       #--J_DBE
       $db2 "UPDATE J_DBE SET ID_ACTION=$j WHERE ID_ACTION=$maxID"
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

       #--
       set TABLE_LIST2 [ list ARC_SERVICES_TUNE ARC_SERVICES_ACCESS ]
       foreach T_NAME $TABLE_LIST2 {
         $db2 "UPDATE $T_NAME SET ID_SPROFILE=$maxID WHERE ID_SPROFILE=$id_old"
         $db2 commit
       }

       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

       #--
       set TABLE_LIST2 [ list ARC_SERVICES_TUNE ARC_SERVICES_ACCESS ]
       foreach T_NAME $TABLE_LIST2 {
         $db2 "UPDATE $T_NAME SET ID_SPROFILE=$j WHERE ID_SPROFILE=$maxID"
         $db2 commit
       }

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

# -- MEAS_LIST
proc MEAS_LIST { rf db2 } {

    set da_list [ list ]
    LogWrite "====MEAS_LIST==="

    set strSQL11 "select id,id_parent, name, id_lsttbl \
from sys_tree21 \
where id_parent in ( \
select distinct id_parent from sys_tree21 where id_lsttbl in \
(select id from sys_tbllst where id_type in \
(select id from sys_otyp where define_alias like 'LST') \
and id_node in \
(select id from sys_db_part where id_parent in \
(select id from sys_db_part where define_alias like 'DA_SUBSYST' ))))"

    foreach {r11} [ $db2 $strSQL11 ] {
      LogWrite $r11
      set id_lsttbl [ lindex $r11 3 ]
      lappend da_list $id_lsttbl
    }
    LogWrite "============"


    set TABLE_NAME "MEAS_LIST"

    set strSQL1 "SELECT max(ID), min(ID), count(*) FROM $TABLE_NAME"
    set maxID 0 ; set minID 0 ; set cntID 0 ;
    foreach {r1} [ $db2 $strSQL1 ] {
      set maxID [ lindex $r1 0 ]
      set minID [ lindex $r1 1 ]
      set cntID [ lindex $r1 2 ]
      set s1 "\n$TABLE_NAME = max=$maxID min=$minID cnt=$cntID \n"
      puts $s1
    }

    LogWrite "======MEAS_LIST======"
    set strSQL11 "SELECT * FROM $TABLE_NAME"
    foreach {r11} [ $db2 $strSQL11 ] {
      LogWrite $r11
    }
    LogWrite "============"

    #set maxID [ expr int($maxID)+1 ]
    #set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_NODE,ID_POINT,ID_UCLASS, PRIORITY, SCALE, SCALE_MAX, SCALE_MIN, NAME, ALIAS, STATE, APERTURE) VALUES ($maxID,1,1,1,0,1,1,1,'TEXTRENAMETEXT','',0,0) "
    #$db2 $strSQL0
    #$db2 commit

    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

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

# -- DA_PARAM
proc DA_PARAM { rf db2 } {

    set da_list [ list ]
    LogWrite "====DA_SUBSYST==="

    set strSQL11 "select id,id_parent, name, id_lsttbl \
from sys_tree21 \
where id_parent in ( \
select distinct id_parent from sys_tree21 where id_lsttbl in \
(select id from sys_tbllst where id_type in \
(select id from sys_otyp where define_alias like 'LST') \
and id_node in \
(select id from sys_db_part where id_parent in \
(select id from sys_db_part where define_alias like 'DA_SUBSYST' ))))"

    foreach {r11} [ $db2 $strSQL11 ] {
      LogWrite $r11
      set id_lsttbl [ lindex $r11 3 ]
      lappend da_list $id_lsttbl
    }
    LogWrite "============"


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

    LogWrite "======DA_PARAM======"
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


       set TABLE_LIST2 [ list DA_ARC  DA_PARGROUP_TUNE DA_PROFILE DA_VAL ]
       foreach T_NAME $TABLE_LIST2 {
         $db2 "UPDATE $T_NAME SET ID_PARAM=$maxID WHERE ID_PARAM=$id_old"
         $db2 commit
       }

       #--DA_SRC_CHANNEL  ID_OWNLST
       $db2 "UPDATE DA_SRC_CHANNEL SET ID_OWNLST=$maxID WHERE ID_OWNLST=$id_old"
       $db2 commit

       #--J_MAILDISP  ID_DIRECTORY
       $db2 "UPDATE J_MAILDISP SET ID_DIRECTORY=$maxID WHERE ID_DIRECTORY=$id_old"
       $db2 commit

       foreach ID_TABLE $da_list {
         #set ID_TABLE 54
         #--VP_PARAMS  ID_PARAM ID_TABLE=54 - SYS_TBLLST(DA_V_LST_1_LST)
         $db2 "UPDATE VP_PARAMS SET ID_PARAM=$maxID WHERE ID_PARAM=$id_old AND ID_TABLE=$ID_TABLE"
         $db2 commit
         #--VS_REGIM_TUNE  ID_PARAM ID_TABLE=54 - SYS_TBLLST(DA_V_LST_1_LST)
         $db2 "UPDATE VS_REGIM_TUNE SET ID_PARAM=$maxID WHERE ID_PARAM=$id_old AND ID_TABLE=$ID_TABLE"
         $db2 commit
       }


       $db2 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 commit


       set TABLE_LIST2 [ list DA_ARC  DA_PARGROUP_TUNE DA_PROFILE DA_VAL ]
       foreach T_NAME $TABLE_LIST2 {
         $db2 "UPDATE $T_NAME SET ID_PARAM=$j WHERE ID_PARAM=$maxID"
         $db2 commit
       }

       #--DA_SRC_CHANNEL  ID_OWNLST
       $db2 "UPDATE DA_SRC_CHANNEL SET ID_OWNLST=$j WHERE ID_OWNLST=$maxID"
       $db2 commit

       #--J_MAILDISP  ID_DIRECTORY
       $db2 "UPDATE J_MAILDISP SET ID_DIRECTORY=$j WHERE ID_DIRECTORY=$maxID"
       $db2 commit

       foreach ID_TABLE $da_list {
         #set ID_TABLE 54
         #--VP_PARAMS  ID_PARAM ID_TABLE=54 - SYS_TBLLST(DA_V_LST_1_LST)
         $db2 "UPDATE VP_PARAMS SET ID_PARAM=$j WHERE ID_PARAM=$maxID AND ID_TABLE=$ID_TABLE"
         $db2 commit
         #--VS_REGIM_TUNE  ID_PARAM ID_TABLE=54 - SYS_TBLLST(DA_V_LST_1_LST)
         $db2 "UPDATE VS_REGIM_TUNE SET ID_PARAM=$j WHERE ID_PARAM=$maxID AND ID_TABLE=$ID_TABLE"
         $db2 commit
       }

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


# -- DA_ARC - correction
proc DA_ARC_correction { rf db2 } {

 #alter table OLD_TABLE rename to NEW_TABLE;
 #rename OLD_TABLE TO NEW_TABLE;

 #RENAME myview TO otherview;

 #alter index owner.index_name rename to new_name;

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

       set TABLE_LIST2 [ list DA_SLAVE  DA_DEV_PROTO  DA_DEV_DESC ]
       foreach T_NAME $TABLE_LIST2 {
         $db2 "UPDATE $T_NAME SET ID_DEV=$maxID WHERE ID_DEV=$id_old"
         $db2 commit
       }


       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit


       set TABLE_LIST2 [ list DA_SLAVE  DA_DEV_PROTO  DA_DEV_DESC ]
       foreach T_NAME $TABLE_LIST2 {
         $db2 "UPDATE $T_NAME SET ID_DEV=$j WHERE ID_DEV=$maxID"
         $db2 commit
       }

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_PROTO_POINT,ID_DEV,ID_PARENT,NAME,CVALIF,ID_TYPE,ID_GTOPT,ATTR_NAME,SCALE) \
  VALUES ($maxID,1,1,$maxID,'TEXTRENAMETEXT',1,405,1,null,1)"
    $db2 $strSQL0
    $db2 commit

    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      ##if {$id_old<=1000} { continue ; }
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

       #--  ID_NODE
       set TABLE_LIST2 [ list DA_DEV_OPT  DA_EQUALIFIER \
         DA_FAILURE_JRNL DA_KTSUSD DA_MASTER  DA_PARAM \
         DA_PC  DA_PORT  DA_SLAVE ]
       foreach T_NAME $TABLE_LIST2 {
         $db2 "UPDATE $T_NAME SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
         $db2 commit
       }

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

       #--  ID_NODE
       set TABLE_LIST2 [ list DA_DEV_OPT  DA_EQUALIFIER \
         DA_FAILURE_JRNL DA_KTSUSD DA_MASTER  DA_PARAM \
         DA_PC  DA_PORT  DA_SLAVE ]
       foreach T_NAME $TABLE_LIST2 {
         $db2 "UPDATE $T_NAME SET ID_NODE=$j WHERE ID_NODE=$maxID"
         $db2 commit
       }

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

    #--  ID_OBJ
    set TABLE_LIST2 [ list AST_LINK DG_GROUPS_DESC EA_POINTS  \
      NTP_EDGE MEAS_LIST \
      OBJ_AUX_EL_PIN OBJ_LIMIT_SET OBJ_NAMES OBJ_PARAM OBJ_PQCURVES \
      OBJ_GENERATOR_PQ \
      OBJ_CNT OBJ_EL_PIN OBJ_EQUALIFIER OBJ_LOCATION OBJ_CONN_NODE OBJ_GEO \
      TOPO_EDGE ]
    foreach T_NAME $TABLE_LIST2 {
      if {[checkTable $rf $db2 $T_NAME "ID_OBJ"]} {
        $db2 "UPDATE $T_NAME SET ID_OBJ=$ind1 WHERE ID_OBJ=$ind2"
        $db2 commit
      }
    }

    #-- ID_SWITCH
    set TABLE_LIST2 [ list OBJ_REFERENCES ]
    foreach T_NAME $TABLE_LIST2 {
      if {[checkTable $rf $db2 $T_NAME "ID_SWITCH"]} {
        $db2 "UPDATE $T_NAME SET ID_SWITCH=$ind1 WHERE ID_SWITCH=$ind2"
        $db2 commit
      }
    }

    #-- ID_OBJ_FEEDER
    set TABLE_LIST2 [ list FEED_PROP ]
    foreach T_NAME $TABLE_LIST2 {
      if {[checkTable $rf $db2 $T_NAME "ID_OBJ_FEEDER"]} {
        $db2 "UPDATE $T_NAME SET ID_OBJ_FEEDER=$ind1 WHERE ID_OBJ_FEEDER=$ind2"
        $db2 commit
      }
    }

    #-- ID_NODE
    set TABLE_LIST2 [ list CALC_LIST TAG_LIST NME_PARAM_LIST ]
    foreach T_NAME $TABLE_LIST2 {
      if {[checkTable $rf $db2 $T_NAME "ID_NODE"]} {
        $db2 "UPDATE $T_NAME SET ID_NODE=$ind1 WHERE ID_NODE=$ind2"
        $db2 commit
      }
    }


    #-- ID_EQUIP
    set TABLE_LIST2 [ list DMS_CALC_RESULT_MEAS ]
    foreach T_NAME $TABLE_LIST2 {
      if {[checkTable $rf $db2 $T_NAME "ID_EQUIP"]} {
        $db2 "UPDATE $T_NAME SET ID_EQUIP=$ind1 WHERE ID_EQUIP=$ind2"
        $db2 commit
      }
    }

    #LOCK TABLE J_ELSET IN SHARE ROW EXCLUSIVE MODE;
    #--  ID_OBJECT
    set TABLE_LIST2 [ list J_ELSET  J_PHSET  J_TELEREG ]
    foreach T_NAME $TABLE_LIST2 {
      if {[checkTable $rf $db2 $T_NAME "ID_OBJECT"]} {
        $db2 "UPDATE $T_NAME SET ID_OBJECT=$ind1 WHERE ID_OBJECT=$ind2"
        $db2 commit
      }
    }


    #--RSDUJOB.JOB_MAIN   JOB_STAMPS   JOB_SWITCH_CONDITIONS
      if {[checkTable $rf $db2 "RSDUJOB.JOB_MAIN" "ID_OBJ"]} {
        $db2 "UPDATE RSDUJOB.JOB_MAIN SET ID_OBJ=$ind1 WHERE ID_OBJ=$ind2"
        $db2 commit
      }
      if {[checkTable $rf $db2 "RSDUJOB.JOB_MAIN" "ID_PURPOSE_OBJ"]} {
        $db2 "UPDATE RSDUJOB.JOB_MAIN SET ID_PURPOSE_OBJ=$ind1 WHERE ID_PURPOSE_OBJ=$ind2"
        $db2 commit
      }
      if {[checkTable $rf $db2 "RSDUJOB.JOB_MAIN" "ID_ENTERPRISE"]} {
        $db2 "UPDATE RSDUJOB.JOB_MAIN SET ID_ENTERPRISE=$ind1 WHERE ID_ENTERPRISE=$ind2"
        $db2 commit
      }
      if {[checkTable $rf $db2 "RSDUJOB.JOB_STAMPS" "ID_ENTERPRISE"]} {
        $db2 "UPDATE RSDUJOB.JOB_STAMPS SET ID_ENTERPRISE=$ind1 WHERE ID_ENTERPRISE=$ind2"
        $db2 commit
      }
      if {[checkTable $rf $db2 "RSDUJOB.JOB_SWITCH_CONDITIONS" "ID_SWITCH"]} {
        $db2 "UPDATE RSDUJOB.JOB_SWITCH_CONDITIONS SET ID_SWITCH=$ind1 WHERE ID_SWITCH=$ind2"
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
          #--- ID_PARENT
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


# -- OBJ_EL_PIN
proc OBJ_EL_PIN { rf db2 } {

  set TABLE_LIST [ list OBJ_EL_PIN ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_OBJ,PIN_NUM,ID_CONN_NODE,GUID,NAME) VALUES ($maxID,NULL,0,NULL,'1','TEXTRENAMETEXT') "
    $db2 $strSQL0
    $db2 commit


    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"


       #--  ID_PIN
       set TABLE_LIST2 [ list MEAS_LIST TAG_LIST DMS_BNODE_PINS DMS_CALC_RESULT_MEAS ]
       foreach T_NAME $TABLE_LIST2 {
         #--
         if {[checkTable $rf $db2 $T_NAME "ID_PIN"]==0} {
           puts "\n$T_NAME or ID = not exists"
           continue
         }
         $db2 "UPDATE $T_NAME SET ID_PIN=$maxID WHERE ID_PIN=$id_old"
         $db2 commit
       }
       #--  ID_EL_PIN
       set TABLE_LIST2 [ list OBJ_AUX_EL_PIN OBJ_LIMIT_SET ]
       foreach T_NAME $TABLE_LIST2 {
         #--
         if {[checkTable $rf $db2 $T_NAME "ID_EL_PIN"]==0} {
           puts "\n$T_NAME or ID = not exists"
           continue
         }
         $db2 "UPDATE $T_NAME SET ID_EL_PIN=$maxID WHERE ID_EL_PIN=$id_old"
         $db2 commit
       }


       #--OBJ_EL_PIN
       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit


       #--  ID_PIN
       set TABLE_LIST2 [ list MEAS_LIST TAG_LIST DMS_BNODE_PINS DMS_CALC_RESULT_MEAS]
       foreach T_NAME $TABLE_LIST2 {
         #--
         if {[checkTable $rf $db2 $T_NAME "ID_PIN"]==0} {
           puts "\n$T_NAME or ID = not exists"
           continue
         }
         $db2 "UPDATE $T_NAME SET ID_PIN=$j WHERE ID_PIN=$maxID"
         $db2 commit
       }
       #--  ID_EL_PIN
       set TABLE_LIST2 [ list OBJ_AUX_EL_PIN OBJ_LIMIT_SET ]
       foreach T_NAME $TABLE_LIST2 {
         #--
         if {[checkTable $rf $db2 $T_NAME "ID_EL_PIN"]==0} {
           puts "\n$T_NAME or ID = not exists"
           continue
         }
         $db2 "UPDATE $T_NAME SET ID_EL_PIN=$j WHERE ID_EL_PIN=$maxID"
         $db2 commit
       }


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

# -- OBJ_CONN_NODE
proc OBJ_CONN_NODE { rf db2 } {

  set TABLE_LIST [ list OBJ_CONN_NODE ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_OBJ,GUID,NAME) VALUES ($maxID,NULL,'1','TEXTRENAMETEXT') "
    $db2 $strSQL0
    $db2 commit


    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"


       #--  ID_CONN_NODE
       set TABLE_LIST2 [ list OBJ_EL_PIN  VS_MODUS_NODE DMS_SCHEMES_BNODES ]

       foreach T_NAME $TABLE_LIST2 {
         #--
         if {[checkTable $rf $db2 $T_NAME "ID_CONN_NODE"]==0} {
           puts "\n$T_NAME or ID = not exists"
           continue
         }
         $db2 "UPDATE $T_NAME SET ID_CONN_NODE=$maxID WHERE ID_CONN_NODE=$id_old"
         $db2 commit
       }

       #--
       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit


       foreach T_NAME $TABLE_LIST2 {
         #--
         if {[checkTable $rf $db2 $T_NAME "ID_CONN_NODE"]==0} {
           puts "\n$T_NAME or ID = not exists"
           continue
         }
         $db2 "UPDATE $T_NAME SET ID_CONN_NODE=$j WHERE ID_CONN_NODE=$maxID"
         $db2 commit
       }


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

# -- OBJ_MODEL
proc OBJ_MODEL { rf db2 } {

  set TABLE_LIST [ list OBJ_MODEL ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_TYPE,NAME,GUID) VALUES ($maxID,NULL,'TEXTRENAMETEXT','1') "
    $db2 $strSQL0
    $db2 commit


    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

       #--  ID_MODEL
       set TABLE_LIST2 [ list OBJ_MODEL_MEAS  OBJ_MODEL_PARAM  OBJ_TREE ]

       foreach T_NAME $TABLE_LIST2 {
         $db2 "UPDATE $T_NAME SET ID_MODEL=$maxID WHERE ID_MODEL=$id_old"
         $db2 commit
       }

       #--
       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

       foreach T_NAME $TABLE_LIST2 {
         $db2 "UPDATE $T_NAME SET ID_MODEL=$j WHERE ID_MODEL=$maxID"
         $db2 commit
       }


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

# -- TAG_LIST
proc TAG_LIST { rf db2 } {

  set TABLE_LIST [ list TAG_LIST ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,DESCRIPTION) VALUES ($maxID,'TEXTRENAMETEXT') "
    $db2 $strSQL0
    $db2 commit

    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

       #--  ID_TAG
       set TABLE_LIST2 [ list TAG_DOCS TAG_POSITION ]

       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_TAG"]} {
         $db2 "UPDATE $T_NAME SET ID_TAG=$maxID WHERE ID_TAG=$id_old"
         $db2 commit
        }
       }


       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit


       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_TAG"]} {
         $db2 "UPDATE $T_NAME SET ID_TAG=$j WHERE ID_TAG=$maxID"
         $db2 commit
        }
       }

      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE DESCRIPTION LIKE '%TEXTRENAMETEXT%' "
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

# -- SYS_WAVE
proc SYS_WAVE { rf db2 } {

  set TABLE_LIST [ list SYS_WAVE ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,name) VALUES ($maxID,'TEXTRENAMETEXT') "
    $db2 $strSQL0
    $db2 commit

    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old!=$j} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j ( maxID=$maxID )"

       #--  ID_FILEWAV
       set TABLE_LIST2 [ list AD_DIR AD_LIST \
 ASENERGY_MEAS ASENERGY_OBJECTS ASENERGY_SERVICES \
 AST_CNT AST_GEO AST_ORG AST_TECH \
 DA_CAT DA_PARAM \
 DBE_ACTION DBE_JOB DBE_STORAGE \
 DG_GROUPS DG_LIST \
 MEAS_LIST \
 OBJ_TREE \
 RSDU_SUBSYST \
 S_GROUPS S_USERS \
 SH_DIR \
 SYS_DB_PART SYS_FTR SYS_SIGN \
 TSSO_MPOFFER TSSO_MPOFFER_GTP TSSO_MPOFFER_REQUEST \
 WRPT_CAT WRPT_TMPL_CAT ]

       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_FILEWAV"]} {
         $db2 "UPDATE $T_NAME SET ID_FILEWAV=$maxID WHERE ID_FILEWAV=$id_old"
         $db2 commit
        }
       }


       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit


       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_FILEWAV"]} {
         $db2 "UPDATE $T_NAME SET ID_FILEWAV=$j WHERE ID_FILEWAV=$maxID"
         $db2 commit
        }
       }

      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE name LIKE '%TEXTRENAMETEXT%' "
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

# -- SYS_TBLLST
proc SYS_TBLLST_1 { rf db2 } {

  set TABLE_LIST [ list SYS_TBLLST ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,NAME,TABLE_NAME,ID_TYPE,DEFINE_ALIAS) VALUES ($maxID,'TEXTRENAMETEXT','TEXTRENAMETEXT',1015,'TEXTRENAMETEXT') "
    $db2 $strSQL0
    $db2 commit


    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    set shift 1500
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old<$shift} { continue ; }
      set j_shift [ expr ($j+$shift) ]
      if {$id_old!=$j_shift} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j_shift ( maxID=$maxID )"

       #--  ID_TAG
       set TABLE_LIST2 [ list TAG_DOCS TAG_POSITION ]

       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_TAG"]} {
         $db2 "UPDATE $T_NAME SET ID_TAG=$maxID WHERE ID_TAG=$id_old"
         $db2 commit
        }
       }


       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit


       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_TAG"]} {
         $db2 "UPDATE $T_NAME SET ID_TAG=$j WHERE ID_TAG=$maxID"
         $db2 commit
        }
       }

      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE name LIKE '%TEXTRENAMETEXT%' "
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

# -- SYS_MEAS_TYPES
proc SYS_MEAS_TYPES { rf db2 } {

  set TABLE_LIST [ list SYS_MEAS_TYPES ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,NAME) VALUES ($maxID,'TEXTRENAMETEXT') "
    $db2 $strSQL0
    $db2 commit


    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    set shift 0
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old<$shift} { continue ; }
      set j_shift [ expr ($j+$shift) ]
      if {$id_old!=$j_shift} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j_shift ( maxID=$maxID )"

       #--  ID_TYPE
       set TABLE_LIST2 [ list CALC_LIST DG_LIST NME_PARAM_LIST ]
       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_TYPE"]} {
         $db2 "UPDATE $T_NAME SET ID_TYPE=$maxID WHERE ID_TYPE=$id_old"
         $db2 commit
        }
       }

       #--  ID_MEAS_TYPE
       set TABLE_LIST2 [ list DMS_CALC_RESULT_MEAS DMS_EXTEQUIV_MEAS MEAS_LIST OBJ_MODEL_MEAS SYS_OTYP_MEAS ]
       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_MEAS_TYPE"]} {
         $db2 "UPDATE $T_NAME SET ID_MEAS_TYPE=$maxID WHERE ID_MEAS_TYPE=$id_old"
         $db2 commit
        }
       }


       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit


       #--  ID_TYPE
       set TABLE_LIST2 [ list CALC_LIST DG_LIST NME_PARAM_LIST ]
       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_TYPE"]} {
         $db2 "UPDATE $T_NAME SET ID_TYPE=$j WHERE ID_TYPE=$maxID"
         $db2 commit
        }
       }

       #--  ID_MEAS_TYPE
       set TABLE_LIST2 [ list DMS_CALC_RESULT_MEAS DMS_EXTEQUIV_MEAS MEAS_LIST OBJ_MODEL_MEAS SYS_OTYP_MEAS ]
       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_MEAS_TYPE"]} {
         $db2 "UPDATE $T_NAME SET ID_MEAS_TYPE=$j WHERE ID_MEAS_TYPE=$maxID"
         $db2 commit
        }
       }

      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE name LIKE '%TEXTRENAMETEXT%' "
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

# -- SYS_PUNIT
proc SYS_PUNIT { rf db2 } {

  set TABLE_LIST [ list SYS_PUNIT ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,NAME) VALUES ($maxID,'TEXTRENAMETEXT') "
    $db2 $strSQL0
    $db2 commit


    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    set shift 0
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old<$shift} { continue ; }
      set j_shift [ expr ($j+$shift) ]
      if {$id_old!=$j_shift} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j_shift ( maxID=$maxID )"

       #--  ID_UNIT
       set TABLE_LIST2 [ list DMS_CALC_RESULT_MEAS DMS_EXTEQUIV_MEAS DMS_CALC_INIPARAMS DMS_CALC_INIPARAMS_DEFAULT \
 OBJ_MODEL_PARAM OBJ_PARAM SYS_MEAS_TYPES SYS_OTYP_PARAM SYS_PARAM_TYPES VS_FORM_PARAMTYPE ]

       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_UNIT"]} {
         $db2 "UPDATE $T_NAME SET ID_UNIT=$maxID WHERE ID_UNIT=$id_old"
         $db2 commit
        }
       }


       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit


       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_UNIT"]} {
         $db2 "UPDATE $T_NAME SET ID_UNIT=$j WHERE ID_UNIT=$maxID"
         $db2 commit
        }
       }

      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE name LIKE '%TEXTRENAMETEXT%' "
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

# -- SYS_PTYP
proc SYS_PTYP { rf db2 } {

  set TABLE_LIST [ list SYS_PTYP ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,NAME) VALUES ($maxID,'TEXTRENAMETEXT') "
    $db2 $strSQL0
    $db2 commit


    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    set shift 1500
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old<$shift} { continue ; }
      set j_shift [ expr ($j+$shift) ]
      if {$id_old!=$j_shift} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j_shift ( maxID=$maxID )"

       #--  ID_PTYPE
       set TABLE_LIST2 [ list OBJ_LIMIT ]
       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_PTYPE"]} {
         $db2 "UPDATE $T_NAME SET ID_PTYPE=$maxID WHERE ID_PTYPE=$id_old"
         $db2 commit
        }
       }

       #--  ID_TYPE
       set TABLE_LIST2 [ list SYS_MEAS_TYPES SYS_PARAM_TYPES SYS_PUNIT ]
       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_TYPE"]} {
         $db2 "UPDATE $T_NAME SET ID_TYPE=$maxID WHERE ID_TYPE=$id_old"
         $db2 commit
        }
       }


       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit


       #--  ID_PTYPE
       set TABLE_LIST2 [ list OBJ_LIMIT ]
       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_PTYPE"]} {
         $db2 "UPDATE $T_NAME SET ID_PTYPE=$j WHERE ID_PTYPE=$maxID"
         $db2 commit
        }
       }

       #--  ID_TYPE
       set TABLE_LIST2 [ list SYS_MEAS_TYPES SYS_PARAM_TYPES SYS_PUNIT ]
       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_TYPE"]} {
         $db2 "UPDATE $T_NAME SET ID_TYPE=$j WHERE ID_TYPE=$maxID"
         $db2 commit
        }
       }


      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE name LIKE '%TEXTRENAMETEXT%' "
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

# -- SYS_PARAM_TYPES
proc SYS_PARAM_TYPES { rf db2 } {

  set TABLE_LIST [ list SYS_PARAM_TYPES ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,NAME) VALUES ($maxID,'TEXTRENAMETEXT') "
    $db2 $strSQL0
    $db2 commit


    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    set shift 1500
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old<$shift} { continue ; }
      set j_shift [ expr ($j+$shift) ]
      if {$id_old!=$j_shift} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j_shift ( maxID=$maxID )"

       #--  ID_PARAM_TYPE
       set TABLE_LIST2 [ list DMS_CALC_INIPARAMS DMS_CALC_INIPARAMS_DEFAULT OBJ_MODEL_PARAM OBJ_PARAM SYS_OTYP_PARAM VS_FORM_INIPARAMS ]

       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_PARAM_TYPE"]} {
         $db2 "UPDATE $T_NAME SET ID_PARAM_TYPE=$maxID WHERE ID_PARAM_TYPE=$id_old"
         $db2 commit
        }
       }


       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit


       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_PARAM_TYPE"]} {
         $db2 "UPDATE $T_NAME SET ID_PARAM_TYPE=$j WHERE ID_PARAM_TYPE=$maxID"
         $db2 commit
        }
       }

      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE name LIKE '%TEXTRENAMETEXT%' "
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

# -- SYS_DB_PART
proc SYS_DB_PART { rf db2 } {

  set TABLE_LIST [ list SYS_DB_PART ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,NAME) VALUES ($maxID,'TEXTRENAMETEXT') "
    $db2 $strSQL0
    $db2 commit


    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    set shift 1500
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old<$shift} { continue ; }
      set j_shift [ expr ($j+$shift) ]
      if {$id_old!=$j_shift} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j_shift ( maxID=$maxID )"

       #--  ID_NODE
       set TABLE_LIST2 [ list SYS_TBLLST ]

       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_NODE"]} {
         $db2 "UPDATE $T_NAME SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
         $db2 commit
        }
       }


       set strSQL3 "UPDATE $TABLE_NAME SET ID_PARENT=$maxID WHERE ID_PARENT=$id_old"
       $db2 $strSQL3
       $db2 commit

       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

       set strSQL3 "UPDATE $TABLE_NAME SET ID_PARENT=$j WHERE ID_PARENT=$maxID"
       $db2 $strSQL3
       $db2 commit


       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_NODE"]} {
         $db2 "UPDATE $T_NAME SET ID_NODE=$j WHERE ID_NODE=$maxID"
         $db2 commit
        }
       }

      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE name LIKE '%TEXTRENAMETEXT%' "
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

# -- SYS_OTYP
proc SYS_OTYP { rf db2 } {

  set TABLE_LIST [ list SYS_OTYP ]

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
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,NAME) VALUES ($maxID,'TEXTRENAMETEXT') "
    $db2 $strSQL0
    $db2 commit


    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
    set shift 1500
    for {set i 0} {$i < $cntID} {incr i} {
      set j [ expr $i+1 ]
      set id_old [lindex $r1 $i ]
      if {$id_old<$shift} { continue ; }
      set j_shift [ expr ($j+$shift) ]
      if {$id_old!=$j_shift} {

       LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$j_shift ( maxID=$maxID )"

       #--  ID_NODE
       set TABLE_LIST2 [ list SYS_TBLLST ]

       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_NODE"]} {
         $db2 "UPDATE $T_NAME SET ID_NODE=$maxID WHERE ID_NODE=$id_old"
         $db2 commit
        }
       }


       set strSQL3 "UPDATE $TABLE_NAME SET ID_PARENT=$maxID WHERE ID_PARENT=$id_old"
       $db2 $strSQL3
       $db2 commit

       set strSQL3 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
       $db2 $strSQL3
       $db2 commit

       set strSQL3 "UPDATE $TABLE_NAME SET ID_PARENT=$j WHERE ID_PARENT=$maxID"
       $db2 $strSQL3
       $db2 commit


       foreach T_NAME $TABLE_LIST2 {
       if {[checkTable $rf $db2 $T_NAME "ID_NODE"]} {
         $db2 "UPDATE $T_NAME SET ID_NODE=$j WHERE ID_NODE=$maxID"
         $db2 commit
        }
       }

      }
    }

    $db2 "DELETE FROM $TABLE_NAME WHERE name LIKE '%TEXTRENAMETEXT%' "
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


# -- одиночные таблицы
#BASE1 $rf db2
#BASE1 $rf db2

# -- RSDU_UPDATE
#RSDU_UPDATE $rf db2


# -- SYS_TREE21 -- ?ломается структура?
#SYS_TREE21  $rf db2

# -- SYS_DB_PART
# # SYS_DB_PART $rf db2


# -- DG_GROUPS корректировка сервис GROUP_ID
#DG_GROUPS  $rf db2


# -- S_GROUPS  - корректировка /etc/ema/host.ini  GROUP_ID
#S_GROUPS $rf db2

# -- из за больших журналов переименовываение занимает большой промежуток времени
# -- после необх менять все id ssbsd и тд.
# --
# -- S_USERS -- необ гасить все модули и запускать после S_GROUPS
# ##S_USERS $rf db2
# -- S_USERS=DB_S_USERS -- необ гасить все модули и запускать после S_GROUPS - ID= КАК db_USERS
# ##S_USERS__DB_S_USERS $rf db2
# -- ПОСЛЕ корректировка /etc/ema/host.ini  USER_ID  + ID SSBSD


# -- AD_DIR
#AD_DIR $rf db2
# -- AD_DTYP ------!!!!--ID_TYPE !!!! не запускать.!!!!! sysmon\ssbsd сильно зависят
# !!!!!####AD_DTYP $rf db2!!!!
# -- AD_LIST
#AD_LIST $rf db2


# -- AST_ORG -------!!!!
# # ##
#AST_ORG  $rf db2

# -- AST_CNT
#AST_CNT  $rf db2


# -- US_BUTTON_DESC -- запускать НЕЛЬЗЯ, потому что id жестко забиты в appbar-e
# ###US_BUTTON_DESC  $rf db2
# -- US_MENU -- уточнять id ID_BUTTON
#US_MENU  $rf db2


# -- SYS_APD
#SYS_APD  $rf db2
# -- !!!!!
# ###
#SYS_APPL $rf db2
#

# -- RPT_DIR
#RPT_DIR $rf db2
# -- RPT_LST  - необходимо проверить ID_TABLE=71 - RPT_LST , ID_APPL=964 - клиент просмотра отчетов
# -- SELECT * FROM SYS_TBLLST WHERE TABLE_NAME like '%RPT_LST%'
# -- SELECT * FROM SYS_APPL WHERE ALIAS like '%crviewer%'
#RPT_LST $rf db2 71 964


# -- VS_GROUP
#VS_GROUP $rf db2
# -- VS_FORM  - необходимо проверить ID_TABLE=43 - VS_FORM_LST , ID_APPL=1232 - schemeviewer.exe
# -- SELECT * FROM SYS_TBLLST WHERE TABLE_NAME like '%VS_FORM_LST%'
# -- SELECT * FROM SYS_APPL WHERE ALIAS like '%schemeviewer%'
#VS_FORM $rf db2 43 1232
# -- VS_COMP - запуск после VS_FORM
#VS_COMP $rf db2


# -- VP_GROUP
#VP_GROUP $rf db2
# -- VP_PANEL - необходимо проверить ID_TABLE=40 - VP_PANEL , ID_APPL=87 - pnview.exe
# -- SELECT * FROM SYS_TBLLST WHERE TABLE_NAME like '%VP_PANEL%'
# -- SELECT * FROM SYS_APPL WHERE ALIAS like '%pnview%'
#VP_PANEL $rf db2 40 87
# -- VP_CTRL
#VP_CTRL $rf db2


# -- R_GROUP
#R_GROUP $rf db2
#  -- R_KADR  - необходимо проверить ID_TABLE=46 - R_KADR , ID_APPL=602 - retroview_live.exe
# -- SELECT * FROM SYS_TBLLST WHERE TABLE_NAME like '%R_KADR%'
# -- SELECT * FROM SYS_APPL WHERE ALIAS like '%retroview_live%'
#R_KADR $rf db2 46 602



# -- J_DBE - полностью очистить
# -- DBE_STORAGE
#DBE_STORAGE $rf db2
# -- DBE_JOB
#DBE_JOB $rf db2
# -- DBE_ACTION
#DBE_ACTION $rf db2



# -- ARC_SUBSYST_PROFILE
#ARC1 $rf db2


# -- журналы -- отключать ssbsd
# AA2 $rf db2


# не запускать
# -- MEAS_LIST - запускать очень осторожно, если нет привязки к отчетам - !нет переименовывания таблиц\view архивов !
# --
# ##### MEAS_LIST $rf db2
#

# не запускать
# -- DA_PARAM - запускать очень осторожно, если нет привязки к отчетам - !нет переименовывания таблиц\view архивов !
# -- контроль квалификаторов! в DA_DEV_DESC id могут для контроля Приборов. также id в LUA.
# ##### DA_PARAM $rf db2
# нарушаются привязки в Электрическом режиме

# -- DA_DEV
#DA_DEV $rf db2

# -- DA_DEV_DESC - уточнить ID_PROTO_POINT = 51 (по умолчанию)
#DA_DEV_DESC $rf db2

# -- DA_CAT -- отключать ssbsd + перестроить view с новыми id
#DA_CAT $rf db2


# -- OBJ_TREE -- отключать ssbsd + контроль Сигнальной системы
# -- !необходимо! гасить модули elregd, phregd, ?ssbsd? - ! ОТЧЕТЫ - корректировка обьектов в процедурах!
# #####
#OBJ_TREE $rf db2
#
# -- OBJ_EL_PIN
#OBJ_EL_PIN $rf db2
# -- OBJ_CONN_NODE
#OBJ_CONN_NODE $rf db2
# -- OBJ_MODEL
#OBJ_MODEL $rf db2
#



# -- TAG_LIST
# # TAG_LIST $rf db2


# -- SYS_WAVE   -- не рекомендуем запускать, может возникнуть коллизия в именах файлов
# ## SYS_WAVE $rf db2


# -- SYS_TBLLST
# # SYS_TBLLST_1 $rf db2


# -- SYS_MEAS_TYPES
# SYS_MEAS_TYPES $rf db2

# -- SYS_PUNIT
# #  SYS_PUNIT $rf db2

# -- SYS_PTYP
# # SYS_PTYP $rf db2

# -- SYS_PARAM_TYPES
# # SYS_PARAM_TYPES $rf db2

# -- SYS_OTYP
# # SYS_OTYP $rf db2

# ==============================================================================================================


  flush $rf

# ===============================================
# Закрываем соединение к БД
#  db2 commit
  db2 disconnect

  close $rf

  puts "-- End --"


