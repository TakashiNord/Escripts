

package require tclodbc
package require sqlite3

set tns "rsdu2"
set usr "rsduadmin" ; #  admin  nov_ema
set pwd "passme" ; # passme  qwertyqaz

puts "-- Start --"

global db2

# лог - файл
  set ph [info script]
  if {$ph==""} {
    set ph rsduadmin_dg_guid.log
  } else {
    set ph [file rootname $ph ].log
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
proc checkTable { rf db2 tblname } {
  set strSQL1 "SELECT count(*) FROM $tblname"
  set err ""
  catch {
    set df [ $db2 $strSQL1 ]
    set p ""
  } err
  puts "-- $tblname"
  if {$err!=""} { return 0 ; }
  return 1 ;
}


# ===============================================

# --
proc AA1 { rf db2 } {

  set TABLE_LIST [ list OBJ_MODEL_MEAS DA_SLAVE \
                        RSDU_UPDATE RPT_LST  ]

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


# -- DA_DEV
proc BB { rf db2 } {

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


# -- DA_DEV_DESC
proc BB2 { rf db2 } {

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


proc CC0 { rf db2 a b } {
        #--AST_LINK ID_OBJ
        if {[checkTable $rf $db2 "AST_LINK"]} {
          $db2 "UPDATE AST_LINK SET ID_OBJ=$a WHERE ID_OBJ=$b"
          $db2 commit
        }
        #--CALC_LIST  ID_NODE
        if {[checkTable $rf $db2 "CALC_LIST"]} {
          $db2 "UPDATE CALC_LIST SET ID_NODE=$a WHERE ID_NODE=$b"
          $db2 commit
        }
        #--DG_GROUPS_DESC ID_OBJ
        if {[checkTable $rf $db2 "DG_GROUPS_DESC"]} {
          $db2 "UPDATE DG_GROUPS_DESC SET ID_OBJ=$a WHERE ID_OBJ=$b"
          $db2 commit
        }
        #--EA_POINTS  ID_OBJ
        if {[checkTable $rf $db2 "EA_POINTS"]} {
          $db2 "UPDATE EA_POINTS SET ID_OBJ=$a WHERE ID_OBJ=$b"
          $db2 commit
        }

        #--FEED_PROP  ID_OBJ
        if {[checkTable $rf $db2 "FEED_PROP"]} {
          $db2 "UPDATE FEED_PROP SET ID_OBJ_FEEDER=$a WHERE ID_OBJ_FEEDER=$b"
          $db2 commit
        }

        #--NTP_EDGE  ID_OBJ
        if {[checkTable $rf $db2 "NTP_EDGE"]} {
          $db2 "UPDATE NTP_EDGE SET ID_OBJ=$a WHERE ID_OBJ=$b"
          $db2 commit
        }

        #--MEAS_LIST  ID_OBJ
        if {[checkTable $rf $db2 "MEAS_LIST"]} {
          $db2 "UPDATE MEAS_LIST SET ID_OBJ=$a WHERE ID_OBJ=$b"
          $db2 commit
        }

        #--J_ELSET ID_OBJECT
        if {[checkTable $rf $db2 "J_ELSET"]} {
          $db2 "UPDATE J_ELSET SET ID_OBJECT=$a WHERE ID_OBJECT=$b"
          $db2 commit
        }
        #--J_PHSET  ID_OBJECT
        if {[checkTable $rf $db2 "J_PHSET"]} {
          $db2 "UPDATE J_PHSET SET ID_OBJECT=$a WHERE ID_OBJECT=$b"
          $db2 commit
        }

        #--J_TELEREG  ID_OBJECT
        if {[checkTable $rf $db2 "J_TELEREG"]} {
          $db2 "UPDATE J_TELEREG SET ID_OBJECT=$a WHERE ID_OBJECT=$b"
          $db2 commit
        }

        #--OBJ_CNT  ID_OBJ
        if {[checkTable $rf $db2 "OBJ_CNT"]} {
          $db2 "UPDATE OBJ_CNT SET ID_OBJ=$a WHERE ID_OBJ=$b"
          $db2 commit
            }
        #--OBJ_EL_PIN  ID_OBJ
        if {[checkTable $rf $db2 "OBJ_EL_PIN"]} {
          $db2 "UPDATE OBJ_EL_PIN SET ID_OBJ=$a WHERE ID_OBJ=$b"
          $db2 commit
        }
        #--OBJ_LOCATION  ID_OBJ
        if {[checkTable $rf $db2 "OBJ_LOCATION"]} {
          $db2 "UPDATE OBJ_LOCATION SET ID_OBJ=$a WHERE ID_OBJ=$b"
          $db2 commit
        }
        #--OBJ_PARAM  ID_OBJ
        if {[checkTable $rf $db2 "OBJ_PARAM"]} {
          $db2 "UPDATE OBJ_PARAM SET ID_OBJ=$a WHERE ID_OBJ=$b"
          $db2 commit
        }

        #--OBJ_CONN_NODE  ID_OBJ
        if {[checkTable $rf $db2 "OBJ_CONN_NODE"]} {
          $db2 "UPDATE OBJ_CONN_NODE SET ID_OBJ=$a WHERE ID_OBJ=$b"
          $db2 commit
        }
        #--OBJ_GEO  ID_OBJ
        if {[checkTable $rf $db2 "OBJ_GEO"]} {
          $db2 "UPDATE OBJ_GEO SET ID_OBJ=$a WHERE ID_OBJ=$b"
          $db2 commit
        }
        #--OBJ_REFERENCES  ID_OBJ
        if {[checkTable $rf $db2 "OBJ_REFERENCES"]} {
          $db2 "UPDATE OBJ_REFERENCES SET ID_OBJ=$a WHERE ID_OBJ=$b"
          $db2 commit
        }

        #--TAG_LIST  ID_NODE
        if {[checkTable $rf $db2 "TAG_LIST"]} {
          $db2 "UPDATE TAG_LIST SET ID_NODE=$a WHERE ID_NODE=$b"
          $db2 commit
        }
}

# -- OBJ_TREE
proc CC1 { rf db2 } {

    # !необходимо! гасить модули elregd, phregd, ?ssbsd?

    set shiftID 100 ; # смещение id

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
	  
	    CC0 $rf $db2 $maxID $id_old

        if {[checkTable $rf $db2 $TABLE_NAME ]} {
          #-------  ID_PARENT
          $db2 "UPDATE $TABLE_NAME SET ID_PARENT=$maxID WHERE ID_PARENT=$id_old"
          $db2 commit
          $db2 "UPDATE $TABLE_NAME SET ID=$j WHERE ID=$id_old"
          $db2 commit
          #--  ID_PARENT
          $db2 "UPDATE $TABLE_NAME SET ID_PARENT=$j WHERE ID_PARENT=$maxID"
          $db2 commit
        }

        CC0 $rf $db2 $j $maxID 


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





# -- одиночные таблицы
# AA1 $rf db2

# -- журналы
# AA2 $rf db2

# -- DA_DEV
#BB $rf db2

# -- DA_DEV_DESC
# BB2 $rf db2

# -- OBJ_TREE
CC1 $rf db2








  flush $rf

# ===============================================
# Закрываем соединение к БД
#  db2 commit
  db2 disconnect

  close $rf

  puts "-- End --"


