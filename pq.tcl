#
# Подключаем 2-а пакета: для работы с деревом + для подключения к БД через ODBC
package require tclodbc

  global tns usr pwd
  global db
  global rf

  set tns "poli24" ; #"rsdu2"  "RSDU_ATEC" "Postrsdu5" "poli24"
  set usr "rsduadmin" ; #  admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz

#=============================================
proc LogWrite  { s } {
#=============================================
  global rf
  if {![info exists rf]} { return }
  if {$rf==""} { return }
  puts $rf $s
}
#=============================================
proc LogFlush  { } {
#=============================================
  global rf
  if {![info exists rf]} { return }
  if {$rf==""} { return }
  flush $rf
}



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

#=============================================
proc pq_1 { } {
#=============================================
  global db
  LogWrite "\n-- -- pq_1"

  set cnt "0"
  set str1 "SELECT count(*) FROM OBJ_GENERATOR_PQ"
  foreach {x} [ db $str1 ] {
    set cnt [ lindex $x 0 ]
  }
  puts "OBJ_GENERATOR_PQ = $cnt"

  if { $cnt=="0" } {return 0 ;}

  set cntOBJ 0

  set str1 "SELECT DISTINCT ID_OBJ FROM OBJ_GENERATOR_PQ"
  foreach {xx} [ db $str1 ] {
    set ID_OBJx [ lindex $xx 0 ]
    puts "-- -- $ID_OBJx"

    set stName ""
    set str2 "SELECT ID,NAME FROM OBJ_TREE WHERE ID=$ID_OBJx "
    foreach {x} [ db $str2 ] {
      set stName        [ lindex $x 1 ]
      puts "----$stName"
    }
    puts "--"

    set str2 "SELECT ID,ID_OBJ,PERCENT_PU,P,Q_MIN_BASE,Q_MAX_BASE,Q_MIN_ACT,Q_MAX_ACT FROM OBJ_GENERATOR_PQ WHERE ID_OBJ=$ID_OBJx ORDER BY ID_OBJ,PERCENT_PU"
    foreach {x} [ db $str2 ] {
      set ID         [ lindex $x 0 ]
      set ID_OBJ     [ lindex $x 1 ]
      set PERCENT_PU [ lindex $x 2 ]
      set P          [ lindex $x 3 ]
      set Q_MIN_BASE [ lindex $x 4 ]
      set Q_MAX_BASE [ lindex $x 5 ]
      set Q_MIN_ACT  [ lindex $x 6 ]
      set Q_MAX_ACT  [ lindex $x 7 ]
      set s1 "INSERT INTO OBJ_GENERATOR_PQ (ID,ID_OBJ,PERCENT_PU,P,Q_MIN_BASE,Q_MAX_BASE,Q_MIN_ACT,Q_MAX_ACT ) VALUES "
      set s2 " ( $ID , $ID_OBJ , $PERCENT_PU , $P , $Q_MIN_BASE , $Q_MAX_BASE , $Q_MIN_ACT , $Q_MAX_ACT ) ; "
      set s3 "${s1}${s2}"
      # stage 4
      LogWrite "$s3"
    }
    LogWrite "\n--"
    incr cntOBJ ;
    foreach {x} [ db $str2 ] {
      set ID         [ lindex $x 0 ]
      set ID_OBJ     [ lindex $x 1 ]
      set PERCENT_PU [ lindex $x 2 ]
      set P          [ lindex $x 3 ]
      set Q_MIN_BASE [ lindex $x 4 ]
      set Q_MAX_BASE [ lindex $x 5 ]
      set Q_MIN_ACT  [ lindex $x 6 ]
      set Q_MAX_ACT  [ lindex $x 7 ]
      set s1 "INSERT INTO OBJ_CURVE_DATA (ID_CURVE,PERCENT_PU,XVALUE,Y1VALUE,Y2VALUE ) VALUES "
      set s2 " ( $cntOBJ , $PERCENT_PU , $P , $Q_MIN_BASE , $Q_MAX_BASE ) ; "
      set s3 "${s1}${s2}"
    # stage 3
      LogWrite "$s3"
    }

    set s1 "INSERT INTO OBJ_PQCURVES (ID_OBJ,ID_PQCURVE,IS_DEFAULT ) VALUES "
    set s2 " ( $ID_OBJx , $cntOBJ , 1 ) ; "
    set s3 "${s1}${s2}"
    # stage 2
    LogWrite "$s3"

    set s1 "INSERT INTO OBJ_CURVES (ID,GUID,NAME,CURVE_STYLE_VAL ) VALUES "

    set sg "261DFF3C61B443238012298A50A879"
    set sn [ format "%02d" $cntOBJ ]
    set s2 " ( $cntOBJ , '${sg}${sn}', 'PQ-диаграмма ТГ-${stName}' , 2) ; "

    set s3 "${s1}${s2}"
    # stage 1
    LogWrite "$s3"
  }

  LogWrite "-- -- COMMIT ;"

  return 0 ;
}



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

#26 261DFF3C61B443238012298A50A87980  PQ-диаграмма ТГ №2  2
#17 5BAFCA0D3D304967ABF1D23107541DE5  PQ-диаграмма ТГ №1  2
#19 8437BAE152C449E48716B297FB43891D  PQ-диаграмма ТГ №3  2
#20 E7F1AECB3B0F4D05AAC1DC6F3E6EBFF9  PQ-диаграмма ТГ №4  2
#24 23B13C58D1A64462BC28063D06F8199C  PQ-диаграмма ТГ №5  2

#=============================================
proc pq_2 { } {
#=============================================
  global db
  LogWrite "\n-- -- pq_2"

  set str1 "SELECT ID,GUID,NAME,CURVE_STYLE_VAL FROM OBJ_CURVES"
  foreach {x} [ db $str1 ] {
    set ID               [ lindex $x 0 ]
    set GUID          [format "%s" [ lindex $x 1 ] ]
    set NAME             [ lindex $x 2 ]
    set CURVE_STYLE_VAL  [ lindex $x 3 ]
    set s1 "INSERT INTO OBJ_CURVES (ID,GUID,NAME,CURVE_STYLE_VAL) VALUES "
    set s2 " ( $ID , '$GUID' , '$NAME' , $CURVE_STYLE_VAL ) ; "
    set s3 "${s1}${s2}"
    # stage 4
    LogWrite "$s3"
  }

  set str1 "SELECT ID_OBJ,ID_PQCURVE,IS_DEFAULT FROM OBJ_PQCURVES"
  foreach {x} [ db $str1 ] {
    set ID_OBJ               [ lindex $x 0 ]
    set ID_PQCURVE           [ lindex $x 1 ]
    set IS_DEFAULT           [ lindex $x 2 ]
    set s1 "INSERT INTO OBJ_CURVES (ID_OBJ,ID_PQCURVE,IS_DEFAULTL) VALUES "
    set s2 " ( $ID_OBJ , $ID_PQCURVE , $IS_DEFAULT ) ; "
    set s3 "${s1}${s2}"
    # stage 3
    LogWrite "$s3"
  }

  set cnt 0
  set str1 "SELECT DISTINCT ID_CURVE FROM OBJ_CURVE_DATA"
  foreach {xx} [ db $str1 ] {
    set ID_CURVEx [ lindex $xx 0 ]
    LogWrite "\n-- -- $ID_CURVEx"
    set str2 "SELECT ID_CURVE,PERCENT_PU,XVALUE,Y1VALUE,Y2VALUE FROM OBJ_CURVE_DATA WHERE ID_CURVE=$ID_CURVEx ;"
    foreach {x} [ db $str2 ] {
      set ID_CURVE    [ lindex $x 0 ]
      set PERCENT_PU  [ lindex $x 1 ]
      set XVALUE      [ lindex $x 2 ]
      set Y1VALUE     [ lindex $x 3 ]
      set Y2VALUE     [ lindex $x 4 ]
      set s1 "INSERT INTO OBJ_CURVE_DATA (ID_CURVE,PERCENT_PU,XVALUE,Y1VALUE,Y2VALUE ) VALUES "
      set s2 " ( $ID_CURVE , $PERCENT_PU , $XVALUE , $Y1VALUE , $Y2VALUE ) ; "
      set s3 "${s1}${s2}"
      # stage 2
      LogWrite "$s3"
    }
    LogWrite "\n--"
    foreach {x} [ db $str2 ] {
      incr cnt ;
      set ID_CURVE    [ lindex $x 0 ]
      set PERCENT_PU  [ lindex $x 1 ]
      set XVALUE      [ lindex $x 2 ]
      set Y1VALUE     [ lindex $x 3 ]
      set Y2VALUE     [ lindex $x 4 ]
      set s1 "INSERT INTO OBJ_GENERATOR_PQ (ID,ID_OBJ,PERCENT_PU,P,Q_MIN_BASE,Q_MAX_BASE,Q_MIN_ACT,Q_MAX_ACT ) VALUES "
      set s2 " ( $cnt , $ID_CURVE , $PERCENT_PU , $XVALUE , $Y1VALUE , $Y2VALUE , $Y1VALUE , $Y2VALUE ) ; "
      set s3 "${s1}${s2}"
      # stage 1
      LogWrite "$s3"
    }
  }

  LogWrite "-- -- COMMIT ;"

  return 0 ;
}


#=============================================
proc main { } {
#=============================================
  global tns usr pwd
  global db
  global rf

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\n----start = $t1\n Open log file"

  set tN [ clock format [ clock seconds ] -format "%Y%m%d_%H%M%S" ]
# лог - файл
  set ph [info script]
  if {$ph==""} {
    set ph ${tns}_pq_${tN}.log
  } else {
    set ph [ file rootname $ph ]_${tN}.log
  }
  set rf [ open $ph "w+"  ]

  LogWrite "--START=$t1\n"

# Устанавливаем соединение к БД
  database db $tns $usr $pwd
  #db set autocommit off

  pq_1
  #
  set err ""
  catch { pq_2 } err2
  puts "--\n $err2"

# Закрываем соединение к БД
  #db commit
  db disconnect

  LogWrite "\n--END=$t1"
  LogFlush

  close $rf

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\n----end = $t1\n Save file."

  return
}

main

