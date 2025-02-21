# ===============================================================
#
#
#
#
#
#
# ===============================================================
package require tclodbc
package require sqlite3


proc LogWrite  { s } {
  global rf
  if {![info exists rf]} { return }
  if {$rf==""} { return }
  puts $rf $s
}

# --
proc sys_tree21_topname { db2 } {
# --
  set idnm ""; set name "" ;
  set strSQL1 "select id,name as sys_tree21_topname from sys_tree21 where id_parent is null;"
  set df ""
  set err ""
  catch {
    set df [ $db2 $strSQL1 ]
    set p ""
  } err
  if {$err!=""} { return $name ; }
  foreach {r1} $df {
    set idnm [ lindex $r1 0 ]
    set name [ lindex $r1 1 ]
    puts "\n(${idnm})${name}\n"
  }  
 
  return "(${idnm})${name}" ;
}

# --
proc checkTable { db2 tblname col } {
# --
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

# --
proc changeTable { db2 ind1 ind2 col TABLE_LIST2 } {
# --
  foreach T_NAME $TABLE_LIST2 {
    if {[ checkTable $db2 $T_NAME $col ]} {
      $db2 "UPDATE $T_NAME SET $col=$ind1 WHERE $col=$ind2"
      $db2 commit
    }
  }

  return 0
}

# --
proc selectParamTable { db2 TABLE_NAME } {
# --
    set strSQL1 "SELECT max(ID), min(ID), count(*) FROM $TABLE_NAME"

    set maxID 0 ; set minID 0 ; set cntID 0 ;
    foreach {r1} [ $db2 $strSQL1 ] {
      set err ""
	  catch {
        set maxID [ lindex $r1 0 ]
        set minID [ lindex $r1 1 ]
        set cntID [ lindex $r1 2 ]
        set p ""
      } err
      if {$err!=""} {
        set maxID 0 ; set minID 0 ; set cntID 0 ;
      }	
      set s1 "\n$TABLE_NAME = max=$maxID min=$minID cnt=$cntID \n"
      puts $s1
    }
    set ret [ list  $maxID $minID $cntID ]
    return $ret
}

# --
proc changeSeq { db2 TABLE_NAME } {
# --
  set strSQL3 "SELECT ${TABLE_NAME}_S.nextval FROM dual"
  set err ""
  catch {
    set r3 [ $db2 $strSQL3 ]
    set p ""
  } err
  if {$err!=""} {
    LogWrite "$strSQL3 ( err=$err )"
    return -1 ;#continue
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

  return 0
}


# ==============================================================================================================

# -- DA_CAT -- отключать ssbsd + перестроить view da_v_cat_XXX     с новыми id
proc DA_CAT { db2 shift } {

    set TABLE_NAME "DA_CAT"

    # get param table
    set aret [ split [ selectParamTable $db2 $TABLE_NAME ] ]
    set maxID [lindex $aret 0 ]
    set cntID [lindex $aret 2 ]


    set strSQL1 "SELECT * FROM $TABLE_NAME ORDER BY ID ASC"
    foreach {r1} [ $db2 $strSQL1 ] {
      set s0 "$r1"
      LogWrite "$r1"
    }

    LogWrite "----------\n"
    #return ;

    # insert temp record
    set maxID [ expr int($maxID)+1 ]
    set strSQL0 "INSERT INTO $TABLE_NAME (ID,ID_TYPE,ID_PARENT,NAME,ALIAS,ID_RESERVE,ID_FILEWAV) VALUES ($maxID,1,NULL,'TEXTRENAMETEXT','',NULL,NULL) "
    $db2 $strSQL0
    $db2 commit

    # change id
    set strSQL2 "SELECT ID FROM $TABLE_NAME ORDER BY ID ASC"
    set r1 [ $db2 $strSQL2 ]
	
    #set shift 1500
    set n 0	
    for {set i 0} {$i < $cntID} {incr i} {
      set id_new [ expr $i+1 ]
      set id_old [lindex $r1 $i ]

      if {$id_old<$shift} { set n 0 ; continue ; }
      if {$shift>0} {
        incr n
        set id_new [ expr ($shift + $n) ]
      }

      if {$id_old==$id_new} { continue ; }
	  #if {$id_old!=2000326} { continue ; }

      LogWrite "$TABLE_NAME id_old=$id_old  - >  new=$id_new ( maxID=$maxID )"

      #-- ID_NODE
      set TABLE_LIST2 [ list DA_DEV_OPT  DA_EQUALIFIER \
        DA_FAILURE_JRNL DA_KTSUSD DA_MASTER  DA_PARAM \
        DA_PC  DA_PORT  DA_SLAVE ]
      changeTable $db2 $maxID $id_old "ID_NODE" $TABLE_LIST2

      #-- ID_DEVICE
      set TABLE_LIST3 [ list J_DADV  J_DAPARAMSTATE ]
      changeTable $db2 $maxID $id_old "ID_DEVICE" $TABLE_LIST3


      #--DA_CAT  ID_RESERVE
      $db2 "UPDATE $TABLE_NAME SET ID_RESERVE=$maxID WHERE ID_RESERVE=$id_old"
      $db2 commit
      #--DA_CAT  ID_PARENT
      $db2 "UPDATE $TABLE_NAME SET ID_PARENT=$maxID WHERE ID_PARENT=$id_old"
      $db2 commit

      set strSQL3 "UPDATE $TABLE_NAME SET ID=$id_new WHERE ID=$id_old"
      $db2 $strSQL3
      $db2 commit

      #--DA_CAT  ID_RESERVE
      $db2 "UPDATE $TABLE_NAME SET ID_RESERVE=$id_new WHERE ID_RESERVE=$maxID"
      $db2 commit
      #--DA_CAT  ID_PARENT
      $db2 "UPDATE $TABLE_NAME SET ID_PARENT=$id_new WHERE ID_PARENT=$maxID"
      $db2 commit


      changeTable $db2 $id_new $maxID "ID_NODE" $TABLE_LIST2

      changeTable $db2 $id_new $maxID "ID_DEVICE" $TABLE_LIST3

    }

    $db2 "DELETE FROM $TABLE_NAME WHERE NAME LIKE '%TEXTRENAMETEXT%' "
    $db2 commit

    changeSeq $db2 $TABLE_NAME


    return 0 ;
}


# ===============================================
proc main { w } { 
# ===============================================
global tns usr pwd
set tns "rsdu2" ; #"rsdu2"  "RSDU_ATEC" "Postrsdu5" "poli24"
set usr "rsduadmin" ; #  admin  nov_ema rsduadmin
set pwd "passme" ; # passme  qwertyqaz Password1

global rf
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

# ===============================================================
#
#
# run
#
#
#
# ===============================================================
  set topname [ sys_tree21_topname db2 ]
  LogWrite "$topname\n"
# ===============================================================

# -- DA_CAT -- отключать ssbsd + перестроить view с новыми id
DA_CAT db2 1500

# ===============================================
# Закрываем соединение к БД
#  db2 commit
  db2 disconnect

  flush $rf
  close $rf

  puts "-- End --"

# ===============================================
#
#
#
#
#
#
# ===============================================

}

 main .

