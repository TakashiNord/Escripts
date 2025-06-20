#
# 1. чтение 1-го xlsx - файла. получение списка Листов, создание файлов с их именами, в режиме w+
# 2. проход по всем файлам. последовательно. 
# 3. проход по каждому листу
# 4. чтение данных, преобразование времени в UTC. запись в файл по имени Листа в режиме a+
#  
package require tcom
#package require sqlite3

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
    set rowCount 1
    set end 0
    while { $end == 0 } {

      if {$rowCount>152520} { set end 1 ; break ; }

      set cv1 [$cells Item $rowCount A]
      set columnValue1 [ $cv1 Text]

      set tm1 [clock scan $columnValue1 -format {%Y-%m-%d %H:%M} -timezone :UTC ]

      set cv2 [$cells Item $rowCount E]
      set columnValue2 [ $cv2 Value]

      puts $fb "-- $columnValue1"
      puts $fb "INSERT INTO DG0000_000 (TIME1970, VAL, STATE) VALUES ( $tm1 , $columnValue2 , 0 );"

      incr rowCount
    }

    close $fb
  }

}

# ===============================================
 puts "-- End --"