
package require tcom

# ================================================================
 puts "-- Start --"

 set owner "RSDUADMIN"

 set wrk [ list ]

 set ex [ list qw.xlsx ]

 set script [info script]
 if {$script != {}} {
   set dir [file dirname $script]
 } else {
   set dir [pwd]
 }

# ===============================================

# Set the path to your excel file.
foreach excelFilePath $ex {
  puts "-- $excelFilePath"

  set fn [file nativename [file join $dir $excelFilePath] ]
  puts "-- $fn"

  set excelApp [::tcom::ref createobject Excel.Application]
  set workbooks [$excelApp Workbooks]
  set workbook [$workbooks Open $fn ]
  set worksheets [$workbook Worksheets]

  set sheetCount [$worksheets Count]
  for {set n 1} {${n}<=${sheetCount}} {incr n} {
    set worksheet [$worksheets Item [expr ${n}]]
    set nm1 [ $worksheet Name]
    lappend wrk $nm1

    set fn1 [file nativename [file join $dir $nm1] ]
    set fb [ open $fn1 w+ ]
    close $fb
  }

  break ;
}

 puts $wrk

# ===============================================

# Set the path to your excel file.
foreach excelFilePath $ex {
  puts "-- $excelFilePath"

  set fn [file join $dir $excelFilePath]
  set fn [file nativename $fn ]

  set excelApp [::tcom::ref createobject Excel.Application]
  set workbooks [$excelApp Workbooks]
  set workbook [$workbooks Open $fn ]
  set worksheets [$workbook Worksheets]

  set sheetCount [$worksheets Count]
  for {set n 1} {${n}<=${sheetCount}} {incr n} {
    set worksheet [$worksheets Item [expr ${n}]]

    set nm1 [ $worksheet Name]
    puts $nm1

    set fn1 [file nativename [file join $dir $nm1] ]
    set fb [ open $fn1 a+ ]

    set cells [$worksheet Cells]

    # Read all the values in column A
	set indx 1
    set rowCount 7
    set end 0
    while { $end == 0 } {

      if {$rowCount>150} { set end 1 ; break ; }

      set cv1 [$cells Item $rowCount G]
      set p1 [ $cv1 Text]

      set cv2 [$cells Item $rowCount H]
      set p2 [ $cv2 Value]

      set cv3 [$cells Item $rowCount I]
      set p3 [ $cv3 Text]

      set cv4 [$cells Item $rowCount J]
      set p4 [ $cv4 Value]

      set cv5 [$cells Item $rowCount K]
      set p5 [ $cv5 Text]

      set cv6 [$cells Item $rowCount L]
      set p6 [ $cv6 Value]

      set cv7 [$cells Item $rowCount M]
      set p7 [ $cv7 Text]

      set cv8 [$cells Item $rowCount N]
      set p8 [ $cv8 Value]

      set cv9 [$cells Item $rowCount O]
      set p9 [ $cv9 Value]

      set cv10 [$cells Item $rowCount P]
      set p10 [ $cv10 Value]

      set cv11 [$cells Item $rowCount Q]
      set p11 [ $cv11 Value]

      incr rowCount

      set cv1 [$cells Item $rowCount G]
      set q1 [ $cv1 Text]

      set cv2 [$cells Item $rowCount H]
      set q2 [ $cv2 Value]

      set cv3 [$cells Item $rowCount I]
      set q3 [ $cv3 Text]

      set cv4 [$cells Item $rowCount J]
      set q4 [ $cv4 Value]

      set cv5 [$cells Item $rowCount K]
      set q5 [ $cv5 Text]

      set cv6 [$cells Item $rowCount L]
      set q6 [ $cv6 Value]

      set cv7 [$cells Item $rowCount M]
      set q7 [ $cv7 Text]

      set cv8 [$cells Item $rowCount N]
      set q8 [ $cv8 Value]

      set cv9 [$cells Item $rowCount O]
      set q9 [ $cv9 Value]

      set cv10 [$cells Item $rowCount P]
      set q10 [ $cv10 Value]

      set cv11 [$cells Item $rowCount Q]
      set q11 [ $cv11 Value]


      incr rowCount

      set cv1 [$cells Item $rowCount G]
      set qmax1 [ $cv1 Text]

      set cv2 [$cells Item $rowCount H]
      set qmax2 [ $cv2 Value]

      set cv3 [$cells Item $rowCount I]
      set qmax3 [ $cv3 Text]

      set cv4 [$cells Item $rowCount J]
      set qmax4 [ $cv4 Value]

      set cv5 [$cells Item $rowCount K]
      set qmax5 [ $cv5 Text]

      set cv6 [$cells Item $rowCount L]
      set qmax6 [ $cv6 Value]

      set cv7 [$cells Item $rowCount M]
      set qmax7 [ $cv7 Text]

      set cv8 [$cells Item $rowCount N]
      set qmax8 [ $cv8 Value]

      set cv9 [$cells Item $rowCount O]
      set qmax9 [ $cv9 Value]

      set cv10 [$cells Item $rowCount P]
      set qmax10 [ $cv10 Value]

      set cv11 [$cells Item $rowCount Q]
      set qmax11 [ $cv11 Value]


      puts $fb "Insert into RSDUADMIN.OBJ_GENERATOR_PQ (ID, ID_OBJ, PERCENT_PU, P, Q_MIN_BASE, Q_MAX_BASE, Q_MIN_ACT, Q_MAX_ACT) Values ( $indx, BBBBB,   0 , $p1 , $q1  , $qmax1  , $q1  , $qmax1  ) ; "
	  incr indx
	  puts $fb "Insert into RSDUADMIN.OBJ_GENERATOR_PQ (ID, ID_OBJ, PERCENT_PU, P, Q_MIN_BASE, Q_MAX_BASE, Q_MIN_ACT, Q_MAX_ACT) Values ( $indx, BBBBB,  10 , $p2 , $q2  , $qmax2  , $q2  , $qmax2  ) ; "
	  incr indx
	  puts $fb "Insert into RSDUADMIN.OBJ_GENERATOR_PQ (ID, ID_OBJ, PERCENT_PU, P, Q_MIN_BASE, Q_MAX_BASE, Q_MIN_ACT, Q_MAX_ACT) Values ( $indx, BBBBB,  20 , $p3 , $q3  , $qmax3  , $q3  , $qmax3  ) ; "
	  incr indx
	  puts $fb "Insert into RSDUADMIN.OBJ_GENERATOR_PQ (ID, ID_OBJ, PERCENT_PU, P, Q_MIN_BASE, Q_MAX_BASE, Q_MIN_ACT, Q_MAX_ACT) Values ( $indx, BBBBB,  30 , $p4 , $q4  , $qmax4  , $q4  , $qmax4  ) ; "
	  incr indx
	  puts $fb "Insert into RSDUADMIN.OBJ_GENERATOR_PQ (ID, ID_OBJ, PERCENT_PU, P, Q_MIN_BASE, Q_MAX_BASE, Q_MIN_ACT, Q_MAX_ACT) Values ( $indx, BBBBB,  40 , $p5 , $q5  , $qmax5  , $q5  , $qmax5  ) ; "
	  incr indx
	  puts $fb "Insert into RSDUADMIN.OBJ_GENERATOR_PQ (ID, ID_OBJ, PERCENT_PU, P, Q_MIN_BASE, Q_MAX_BASE, Q_MIN_ACT, Q_MAX_ACT) Values ( $indx, BBBBB,  50 , $p6 , $q6  , $qmax6  , $q6  , $qmax6  ) ; "
	  incr indx
	  puts $fb "Insert into RSDUADMIN.OBJ_GENERATOR_PQ (ID, ID_OBJ, PERCENT_PU, P, Q_MIN_BASE, Q_MAX_BASE, Q_MIN_ACT, Q_MAX_ACT) Values ( $indx, BBBBB,  60 , $p7 , $q7  , $qmax7  , $q7  , $qmax7  ) ; "
	  incr indx
	  puts $fb "Insert into RSDUADMIN.OBJ_GENERATOR_PQ (ID, ID_OBJ, PERCENT_PU, P, Q_MIN_BASE, Q_MAX_BASE, Q_MIN_ACT, Q_MAX_ACT) Values ( $indx, BBBBB,  70 , $p8 , $q8  , $qmax8  , $q8  , $qmax8  ) ; "
	  incr indx
	  puts $fb "Insert into RSDUADMIN.OBJ_GENERATOR_PQ (ID, ID_OBJ, PERCENT_PU, P, Q_MIN_BASE, Q_MAX_BASE, Q_MIN_ACT, Q_MAX_ACT) Values ( $indx, BBBBB,  80 , $p9 , $q9  , $qmax9  , $q9  , $qmax9  ) ; "
	  incr indx
	  puts $fb "Insert into RSDUADMIN.OBJ_GENERATOR_PQ (ID, ID_OBJ, PERCENT_PU, P, Q_MIN_BASE, Q_MAX_BASE, Q_MIN_ACT, Q_MAX_ACT) Values ( $indx, BBBBB,  90 , $p10, $q10 , $qmax10 , $q10 , $qmax10 ) ; "
	  incr indx
	  puts $fb "Insert into RSDUADMIN.OBJ_GENERATOR_PQ (ID, ID_OBJ, PERCENT_PU, P, Q_MIN_BASE, Q_MAX_BASE, Q_MIN_ACT, Q_MAX_ACT) Values ( $indx, BBBBB, 100 , $p11, $q11 , $qmax11 , $q11 , $qmax11 ) ; "
	  incr indx

      puts $fb "--"

      incr rowCount
    }

    close $fb
  }

}

# ===============================================
 puts "-- End --"