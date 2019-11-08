#
#  скрипт обходит все папки, собирает все файлы.
#    обьединяет все файлы в 1. (.csv) для каждой папки
#
#
#
#


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


# ===============================================
proc  main { } {
# ===============================================
  global rf

# лог - файл
  set ph [info script]
  set ph [file rootname $ph ].log

  set rf [ open $ph "w+"  ]
  fconfigure $rf -encoding utf-8

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nstart = $t1\n"
  LogWrite "--START=$t1\n"

  set dh [info script]
  set dh [file dirname $dh ]

  foreach l [ glob -nocomplain -types d -dir $dh * ] {

    # massiv value (data?value)
    array set db { } ;

    set dirfile [ file tail $l ]
    LogWrite "--dir=$l = $dirfile"

    set s [ glob -nocomplain -dir $l * ]
    foreach f $s {

      set fn [file tail $f ]
      regexp -- {[(]+([0-9])+[)]+} $fn sf
      set sp [ string trim $sf "()" ]

      LogWrite "$f ($sp) \n"

      set r1 [ open $f "r"]

      # column
      if {![info exists db(-2,vl)]}  { set db(-2,vl) "$sp" } else { set db(-2,vl) "$db(-2,vl);$sp" }
      #LogWrite "sp=$db(-2,vl)"

      ##while  { [gets $r1 line] >= 0 }   { ; }
      foreach line [split [read $r1] \n] {
        set val [split $line ";"]
        set dt [lindex $val 0 ]
        set vl [lindex $val 1 ]
        #LogWrite "$dt=$vl"
        if {![info exists db($dt,dt) ]}  { set db($dt,dt) "$dt" }
        if {![info exists db($dt,vl)]}  { set db($dt,vl) "$vl" } else { set db($dt,vl) "$db($dt,vl);$vl" }
        #LogWrite "$db($dt,dt)=$db($dt,vl)"
      }

      close $r1

#     break ;
    }

    set ph [info script]
    if {$ph==""} {
       set ph ${dirfile}.csv
    } else {
       set ph [file dirname $ph ]/${dirfile}.csv
    }

    set fp [open $ph w]

    # output column
    puts $fp "dt;$db(-2,vl)"

    # output value
    foreach {t1 t2} [lsort [array get db *,dt] ] {
      set s $t1
      if {[string match -nocase "*,dt" $s]} { set s $t2 }
      set vt1 $s
      if {$s>0} { set vt1 [ clock format $vt1 -format "%Y.%m.%d %H:%M" ] }
      puts -nonewline $fp "$vt1;"
      foreach {v1 v2} [lsort [array get db $t1,vl ] ] {
        set s $v2
        if {[string match -nocase "*,vl" $s]} { set s $v1 }
        puts -nonewline $fp "${s};"
      }
      puts  $fp " "
    }

    close $fp

    array unset db ;

    #break ;
  }

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nend = $t1"
  LogWrite "\n--END=$t1"

  close $rf

  return 0 ;
}

  main

