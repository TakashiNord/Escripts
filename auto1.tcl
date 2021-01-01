
#
package require tclodbc

#=============================================
proc auto1 { } {
#=============================================
  set tns "rsdu2"
  set usr "rsduadmin" ; #  admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\n----start = $t1\n"

# Устанавливаем соединение к БД
  database db $tns $usr $pwd
#db set autocommit off

  set count  0
  set str1 "select view_name from dba_views where lower(view_name) like 'au0%';"

  foreach {x} [ db $str1 ] {
	set name [ lindex $x 0 ]
        #puts "$name \n"
        set n1 0
	set str2 "select count(*) from $name where from_dt1970(time1970)>(sysdate-36);"
	foreach {y} [ db $str2 ] {
          set n0 [ lindex $y 0 ]
	  set n1 [ expr int($n0) ]
	}
	if {$n1==0} { continue ; }
	puts "$name"
	set str2 "select from_dt1970(time1970), $name.* from $name where from_dt1970(time1970)>(sysdate-36);"
	foreach {z} [ db $str2 ] {
	  puts ${z}
        }
        puts "--"
  }

# Закрываем соединение к БД
  #db commit
  db disconnect

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\n----end = $t1"

  return 0 ;
}


proc main { } {
  auto1
  return
}


main












