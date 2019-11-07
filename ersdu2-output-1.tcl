

package require tclodbc


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
proc  CreateSp { } {
# ===============================================
  global db1
  global db2

  set ph [info script]
  if {$ph==""} {
    set ph [ pwd ]
  } else {
    set ph [file dirname $ph ]
  }

  foreach {r3} [ db2 "select ID ,NAME from da_cat where id_type = 4" ] {
    set id [lindex $r3 0]
    set name [lindex $r3 1]

    set tempname $name

    regsub -all "<" $tempname "(" tempname
    regsub -all ">" $tempname ")" tempname
    regsub -all "/" $tempname "_" tempname
    regsub -all {\\} $tempname "_" tempname
    regsub -all {:} $tempname "=" tempname
    regsub -all {"} $tempname "'" tempname
    set name_file $ph\\${tempname}($id).csv

    LogWrite "$name_file\n"

    set ff [ open $name_file "w+"  ]
    puts $ff "-1;NAME;cvalif"

    set cnt 0 ;
    set s5 [ format "select NAME, id_point from da_param where id_node=%d order by id_point" $id ]
    foreach {r5} [ db2 $s5 ] {
       incr cnt
       set nm [lindex $r5 0]
       set pt [lindex $r5 1]
       puts $ff "$cnt;${nm};$pt"
       LogWrite "--$nm"
    }

    close $ff

  }

  return 0 ;
}


# ===============================================
proc  main { } {
# ===============================================
  global db1
  global db2
  global rf

  # avtorization
  set tns "rsdu2"
  set usr "rsduadmin" ; #  admin  nov_ema
  set pwd "2017'vf-Dbrsdu#" ; # passme  qwertyqaz


# лог - файл
  set ph [info script]
  set ph [file rootname $ph ].log

  set rf [ open $ph "w+"  ]

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nstart = $t1\n"
  LogWrite "--START=$t1\n"

# Устанавливаем соединение к БД
  database db2 $tns $usr $pwd
  db2 set autocommit off

  CreateSp

# Закрываем соединение к БД
#  db2 commit
  db2 disconnect

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nend = $t1"
  LogWrite "\n--END=$t1"

  close $rf

  return 0 ;
}

  main

