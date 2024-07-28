#
# Подключаем 2-а пакета: для работы с деревом + для подключения к БД через ODBC
package require tclodbc

global tns usr pwd
  set tns "rsdu2"
  set usr "rsduadmin" ; #  admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz

# ===============================================
proc LogWrite  { s } {
# ===============================================
  global rf
  if {![info exists rf]} { return }
  if {$rf==""} { return }
  puts $rf $s
}
# ===============================================
proc LogFlush  { } {
# ===============================================
  global rf
  if {![info exists rf]} { return }
  if {$rf==""} { return }
  flush $rf
}

#=============================================
proc pq_1 { } {
#=============================================

  set count  0

  set cnt "0"
  set str1 "SELECT count(*) FROM OBJ_GENERATOR_PQ"
  foreach {x} [ db $str1 ] {
    set cnt [ lindex $x 0 ]
  }
  puts "OBJ_GENERATOR_PQ = $cnt"

  if { $cnt=="0" } {return 0 ;}

  set cntOBJ 0
  set str1 "SELECT count(DISTINCT ID_OBJ) FROM OBJ_GENERATOR_PQ"
  foreach {x} [ db $str1 ] {
    set cntOBJ [ lindex $x 0 ]
  }
  puts "OBJ_GENERATOR_PQ cnt OBJ = $cntOBJ"


  set str1 "SELECT ID,ID_OBJ,PERCENT_PU,P,Q_MIN_BASE,Q_MAX_BASE,Q_MIN_ACT,Q_MAX_ACT FROM OBJ_GENERATOR_PQ ORDER BY ID_OBJ,PERCENT_PU"
  foreach {x} [ db $str1 ] {
    set ID         [ lindex $x 0 ]
    set ID_OBJ     [ lindex $x 1 ]
    set PERCENT_PU [ lindex $x 2 ]
    set P          [ lindex $x 3 ]
    set Q_MIN_BASE [ lindex $x 4 ]
    set Q_MAX_BASE [ lindex $x 5 ]
    set Q_MIN_ACT  [ lindex $x 6 ]
    set Q_MAX_ACT  [ lindex $x 7 ]
    set s1 "INSERT OBJ_GENERATOR_PQ (ID,ID_OBJ,PERCENT_PU,P,Q_MIN_BASE,Q_MAX_BASE,Q_MIN_ACT,Q_MAX_ACT ) VALUES "
    set s2 " ( $ID , $ID_OBJ , $PERCENT_PU , $P , $Q_MIN_BASE , $Q_MAX_BASE , $Q_MIN_ACT , $Q_MAX_ACT ) ; "
    set s3 "${s1}${s2}"
    puts $s3
    LogWrite "\n$s3"

    set s1 "INSERT OBJ_GENERATOR_PQ (ID,ID_OBJ,PERCENT_PU,P,Q_MIN_BASE,Q_MAX_BASE,Q_MIN_ACT,Q_MAX_ACT ) VALUES "
    set s2 " ( $ID , $ID_OBJ , $PERCENT_PU , $P , $Q_MIN_BASE , $Q_MAX_BASE , $Q_MIN_ACT , $Q_MAX_ACT ) ; "
    set s3 "${s1}${s2}"
    puts $s3
    LogWrite "\n$s3"
  }

  return 0 ;
}


proc main { } {
#
  global tns usr pwd
  global db
  global rf

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\n----start = $t1\n"


  set tN [ clock format [ clock seconds ] -format "%Y%m%d_%H%M%S" ]
# лог - файл
  set ph [info script]
  if {$ph==""} {
    set ph ${tns}_sqlite_${tN}.log
  } else {
    set ph [ file rootname $ph ]_${tN}.log
  }
  set rf [ open $ph "w+"  ]

  LogWrite "--START=$t1\n"

# Устанавливаем соединение к БД
  database db $tns $usr $pwd
  #db set autocommit off

  pq_1
  #pq_2

# Закрываем соединение к БД
  #db commit
  db disconnect

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\n----end = $t1\n"

  LogWrite "\n--END=$t1"

  return
}


main



#CREATE TABLE OBJ_GENERATOR_PQ
#(
#  ID          NUMBER(11),
#  ID_OBJ      NUMBER(11) CONSTRAINT OBJ_GENERATOR_PQ_ID_OBJ_NN NOT NULL,
#  PERCENT_PU  NUMBER CONSTRAINT OBJ_GENERATOR_PQ_PERCENT_PU_NN NOT NULL,
#  P           NUMBER CONSTRAINT OBJ_GENERATOR_PQ_P_NN NOT NULL,
#  Q_MIN_BASE  NUMBER CONSTRAINT OBJ_GENERATOR_PQ_Q_MIN_BASE_NN NOT NULL,
#  Q_MAX_BASE  NUMBER CONSTRAINT OBJ_GENERATOR_PQ_Q_MAX_BASE_NN NOT NULL,
#  Q_MIN_ACT   NUMBER CONSTRAINT OBJ_GENERATOR_PQ_Q_MIN_ACT_NN NOT NULL,
#  Q_MAX_ACT   NUMBER CONSTRAINT OBJ_GENERATOR_PQ_Q_MAX_ACT_NN NOT NULL
#)

#obj_tree

#CREATE TABLE OBJ_PQCURVES
#(
#  ID_OBJ      NUMBER(11),
# ID_PQCURVE  NUMBER(11),
#  IS_DEFAULT  NUMBER(1)
#)

#CREATE TABLE OBJ_CURVES
#(
#  ID               NUMBER(11),
#  GUID             RAW(16) CONSTRAINT OBJ_CURVES_GUID_NN NOT NULL,
#  NAME             VARCHAR2(255 CHAR),
#  CURVE_STYLE_VAL  NUMBER(11)
#)
#ID GUID  NAME  CURVE_STYLE_VAL

#26 261DFF3C61B443238012298A50A87980  PQ-диаграмма ТГ №2  2
#17 5BAFCA0D3D304967ABF1D23107541DE5  PQ-диаграмма ТГ №1  2
#19 8437BAE152C449E48716B297FB43891D  PQ-диаграмма ТГ №3  2
#20 E7F1AECB3B0F4D05AAC1DC6F3E6EBFF9  PQ-диаграмма ТГ №4  2
#24 23B13C58D1A64462BC28063D06F8199C  PQ-диаграмма ТГ №5  2

#CREATE TABLE OBJ_CURVE_DATA
#(
#  ID_CURVE    NUMBER(11),
#  PERCENT_PU  NUMBER(11),
#  XVALUE      NUMBER,
#  Y1VALUE     NUMBER,
#  Y2VALUE     NUMBER,
#  Y3VALUE     NUMBER
#)
#











