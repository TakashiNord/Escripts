
package require tclodbc
#package require xml
#package require dom

# ===============================================

set tns "rsdu2"
set usr "rsduadmin" ; #  admin  nov_ema
set pwd "passme" ; # passme  qwertyqaz

  set filename rsdu2.log
  set ph [info script]
  if {$ph==""} {
   set ph rsdu2.log
  } else {
   set ph [file rootname $ph ].log
   }

  set rf [ open $ph "w+"  ]

# Ա󡮠㬨㡥ꡱ捻鮥 衁
 database db $tns $usr $pwd
 db set autocommit off

# ===============================================
set owner "RSDUADMIN"
set strSQL1 "SELECT object_name FROM all_objects WHERE owner = '%s' AND object_type = 'TABLE'"
set strSQL2 "SELECT column_name FROM all_tab_columns WHERE table_name = '%s'"
set strSQL3 "SELECT * FROM %s"


# Ա󡮠㬨㡥ꡐϋڍ
# 𐬠���SE_EXT_CONNECT_OIK CONNECT => SBOR_STAND_READ = (SELECT = da_dev_desc )  BASE_STAND_READ
  if {$usr!="rsduadmin"} {
    db "SET ROLE SBOR_STAND_READ , BASE_STAND_READ"
    db "select * from session_roles"
  }

  set s1 [ format $strSQL1 $owner ]
  foreach {r1} [ db $s1 ] {
    set idName  [lindex $r1 0]
  puts $rf "-- $idName"
  set s2 [ format $strSQL2 $idName ]
  foreach {r2} [ db $s2 ] {
     set idNameCol  [lindex $r2 0]
     puts $rf "-- -- $idNameCol"
  }
  }

  close $rf

# ===============================================


  exit ;


# ===============================================
#  <?xml version="1.0" encoding="utf-8" standalone="yes"?>
#  <Properties>
#   <Author>  </Author>
#   <Created> </Created>
# <Company> </Company>
#   <Version> </Version>
#  </Properties>
#  <Styles>
# //default style
# //Datetime style
# //Hyperlink style
#  </Styles>
#  <dataset>
#   <!-- 󡢫鷠  TableName-->
# <table>
#   <name>TableName</name>
#   <DESCRIBE>
#      <!-- 򫱨𐰠򯨤ᮨ�#   </DESCRIBE>
#   <Row>
#      <col1>  </col1>
#    <col2>  </col2>
#    <col3>  </col3>
#     ...
#   </Row>
#    </table>
# ....
#  </dataset>
# ===============================================
  set filename rsdu2.xml
  set ph [info script]
  if {$ph==""} {
    set ph rsdu2.xml
  } else {
    set ph [file rootname $ph ].xml
  }

  set rf [ open $ph "w+"  ]

  puts $rf {<?xml version="1.0" encoding="utf-8" standalone="yes"?>}
  puts $rf "<Properties>"
  puts $rf "  <Author>EMA</Author>"
  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts $rf "  <Created>$t1</Created>"
  puts $rf "  <Company>EMA</Company>"
  puts $rf "  <Version>1.0</Version>"
  puts $rf "</Properties>"
  puts $rf "<Styles>"
  puts $rf "</Styles>"
  puts $rf "<DATASET>"

  set s1 [ format $strSQL1 $owner ]
  foreach {r1} [ db $s1 ] {
    set idName  [lindex $r1 0]
  puts $rf "  <!-- $idName -->"
  puts $rf "  <$idName>"
  set s2 [ format $strSQL2 $idName ]
  set lCol { }
  foreach {r2} [ db $s2 ] {
     set idNameCol  [lindex $r2 0]
     puts $rf "    <$idNameCol>"
     lappend lCol $idNameCol
  }
  set s3 [ format $strSQL3 $idName ]
  foreach {r3} [ db $s3 ] {
    for {set i 0} {$i<[llength $lCol]} { incr 1} {
       set idNameColT  [lindex $lCol $i]
     set valueColT  [lindex $r3 $i]
       puts $rf "       <$idNameCol>$valueColT</$idNameCol>"
    }
  }
  puts $rf "  </$idName>"
  }
  puts $rf "</DATASET>"

  close $rf

# Ƞ뱻㡥ꡱ捻鮥 衁
#  db commit
  db disconnect



