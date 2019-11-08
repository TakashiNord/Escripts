
# ���������� 2-� ������: ��� ������ � ������� + ��� ����������� � �� ����� ODBC
package require struct::tree
package require tclodbc


#=============================================
#in:
#  tns        - tns name
#  usr        - login
#  pwd        - password
#  crn        - ������������ �������� �������� { 0 - ������� ����� ��� � ��, ���� - ������ ��\�� }
#out:
#  CVS
#=============================================
proc da_dev1 { tns usr pwd crn CVS } {
#=============================================
# ���������� ������, ���� ����� ��� ����������
  upvar $CVS lst ;

# ���������
  set zpr " ,.'\"" ; # ��������� ������� � ��������

# ������������� ���������� � ��
  database db $tns $usr $pwd
#db set autocommit off

# ������������� ����
# �� ��������� = BASE_EXT_CONNECT_OIK CONNECT => SBOR_STAND_READ = (SELECT = da_dev_desc )  BASE_STAND_READ
  if {$usr!="rsduadmin"} {
    db "SET ROLE SBOR_STAND_READ , BASE_STAND_READ"
    db "select * from session_roles"
  }


  set id 1 ; # ��������� ������� �����, ��� ��� ������ ��������� ����� �����������.

  # ����� �� ������ �����������
  set id_dev  1
  set name  ""
  set str1 "select * from da_dev order by name" ; # ������ �������
  set str1 "select id_dev, name from da_dev_desc where nvl(id_parent,-1)=-1 order by id_dev" ; # ������ �������
  foreach {x} [ db $str1 ] {
    set sw [string repeat "-" 50 ]
    set lst [linsert $lst end "\n${sw}\n" ]

    # name
    set idName  [lindex $x 1]
    # id_dev
    set id_dev  [lindex $x 0]

    set sf [ format "%s=%-40s" $id_dev $idName ] ;
    set lst [linsert $lst end "${sf}" ] ;

    # �������� ��������� ������ ���������
    ::struct::tree mytreeID

    # ������ ������� (������)
    set str2 "select id,name,cvalif from da_dev_desc where id_dev=%ld and NVL(id_parent, -1)=-1 order by id"
    set fah2 [ format $str2  $id_dev ]
    foreach {x1} [ db $fah2 ] { mytreeID insert root end [lindex $x1 0] ; }
    # ������������ - ������ (������� ����������� = 0 ������� �� ���� ������))
    set ss 1
    while {$ss} {
      set ss 0
      foreach {id} [ mytreeID leaves ] {
        if {$id=="root"} { continue ; }
        set str3 "select id from da_dev_desc where id_dev=%ld and id_parent=%ld and NVL(id_gtopt,-1)=-1 order by id"
        set fah3 [ format $str3 $id_dev $id ]
        set yl [ db $fah3 ]
        set ss [ expr $ss + [llength $yl] ]
        foreach {y} $yl {
          set v1 [lindex $y 0] ;
          mytreeID insert $id end $v1 ;
        }
      }
    }

    foreach {id56} [ mytreeID leaves ] {
        if {$id56=="root"} { continue ; }
        set str56 "select * from da_dev_desc where id_dev=%ld and id=%ld order by id"
		set fah56 [ format $str56 $id_dev $id56 ]
        set y56 [ db $fah56 ]
        foreach {y} $y56 {
          set s0 [lindex $y 0] ;
		  #set s1 [lindex $y 1] ;
		  #set s2 [lindex $y 2] ;
		  #set s3 [lindex $y 3] ;
		  set s4 [lindex $y 4] ;
		  set s5 [lindex $y 5] ;
		  #set s6 [lindex $y 6] ;
		  set lst [linsert $lst end "${s0}=${s4} " ] ;
        }
	}

    mytreeID destroy
  }


# ��������� ���������� � ��
#db commit
  db disconnect

  return 0 ;
}


#=============================================
proc daDevMain { } {
#=============================================
global   tcl_platform
#============================ ������ ���������
  set tns "rsdu2"
  set usr "rsduadmin" ; #  admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz
  set crn 1 ; # 0 - ������� ����� ��� � ��, ���� - ������ ��\��
  set saveFile 1 ; # ������ � ����
  set nameFile "da_dev1.txt" ; # ��� ����� ��� ���������� ����������
#=============================================

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nstart = $t1\n"

  set ls {};
  set ret [ da_dev1 $tns $usr $pwd $crn ls ]

  if {$saveFile == 1} {
    # ��������� �������� �����
    set path [info script]
    set path [ file normalize $path ]
    set dirname [ file dirname $path ]
    set f0 [file join $dirname $nameFile ]
    set f [ file nativename $f0 ]
    # ��������� �� ���������� � ����
    set fd [ open $f "w+"]
      for {set ind 0} {$ind<[llength $ls]} {incr ind} {
        puts $fd [lindex $ls $ind ] ;
      }
      flush $fd
      close $fd
      if { [file exists $f] == 1} {
         puts "\n File $f created!" ;
      }
  } else {
    for {set ind 0} {$ind<[llength $ls]} {incr ind} {
      puts [lindex $ls $ind ] ;
    }
  }

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nend = $t1"

  return 0 ;
}


daDevMain











