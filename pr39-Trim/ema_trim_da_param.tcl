
�� ������������

# ���������� 2-� ������: ��� ������ � ������� + ��� ����������� � �� ����� ODBC
package require tclodbc

#=============================================
proc DaDevClean {  } {
#=============================================
  set tns "rsdu2"
  set usr "rsduadmin" ; #  admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz
  
  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nstart = $t1\n"

# ������������� ���������� � ��
  database db $tns $usr $pwd
#db set autocommit off

  set count  0
  set str1 "select * from da_param order by name" ; # ������ �������
  foreach {x} [ db $str1 ] {
      puts " "
	  set id [ lindex $x 0 ]
	  set idName1  [ lindex $x 11 ]
	  set idNameA1  [ lindex $x 12 ]
	  set idName2  [ string trim $idName1 ]
	  set idNameA2  [ string trim $idNameA1 ]
	  set l1 [ string length $idName1  ]
	  set l2 [ string length $idName2  ]
	  if {$l1!=$l2} {
	    puts "$id=${idName1}\n$id=${idName2}"
		set str2 [ format "update da_param set name='%s' , alias='%s' where id=%s" $idName2 $idNameA2 $id ]
		puts $str2
		db $str2
		#break;
		incr count;
	  }
	  #puts ${x}
  }
  
  puts "\n count=$count" ;

# ��������� ���������� � ��
  db commit
  db disconnect

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nend = $t1"  
  
  return 0 ;
}

DaDevClean












