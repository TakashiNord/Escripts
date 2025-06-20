#
# Экспорт таблиц
#
package require tcom
package require sqlite3

# ================================================================



# ================================================================

proc dumpInterface {obj} {
    set interface [::tcom::info interface $obj]
    puts "interface [$interface name]"

    set properties [$interface properties]
    foreach property $properties {
        puts "property $property"
    }

    set methods [$interface methods]
    foreach method $methods {
	puts "method [lrange $method 0 2] \{"
	set parameters [lindex $method 3]
	foreach parameter $parameters {
            puts "    \{$parameter\}"
	}
	puts "\}"
    }
}

 puts "-- Start --"

 set owner "RSDUADMIN"

# ===============================================
  set cp 0
  
 set script [info script]
 if {$script != {}} {
   set dir [file dirname $script]
 } else {
   set dir [pwd]
 }  
  
  
 set wrk [ list ]

 set ex [ list RSDU_DG_VOL_20211202.xlsx RSDU_DG_VOL_20211203.xlsx RSDU_DG_VOL_20211204.xlsx \
    RSDU_DG_VOL_20211205.xlsx RSDU_DG_VOL_20211206.xlsx RSDU_DG_VOL_20211207.xlsx ]

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
	lappend wrk $worksheet
 }
break ;
} 

puts $wrk





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
 
    set phlog [file join $dir $excelFilePath-$nm1].txt
    set fb [ open $phlog w+ ]
 
    set cells [$worksheet Cells]

 # Read all the values in column A
 set rowCount 5
 set end 0
 while { $end == 0 } {
 
    if {$rowCount==29} { set end 1 ; break ; }
 
    set cv1 [$cells Item $rowCount A]
    set columnValue1 [ $cv1 Text]
  
    set tm1 [clock scan $columnValue1 -format {%d.%m.%Y %H:%M} -timezone :UTC ]
 
    set cv2 [$cells Item $rowCount C]
    set columnValue2 [ $cv2 Value]

    puts $fb "-- $columnValue1"
    puts $fb "INSERT INTO DG023_000 (TIME1970, VAL, STATE) VALUES ( $tm1 , $columnValue2 , 0 );"
    
	incr rowCount
 }
 
 close $fb 


}

}


  puts "count = $cp"

# ===============================================

  puts "-- End --"
