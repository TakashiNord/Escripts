

# ���������� 2-� ������: ��� ������ COM + ��� ����������� � �� ����� ODBC
#package require tcom
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
proc da_dev2 { tns usr pwd fsql CVS id_parent saveFile} {
#=============================================
# ���������� ������, ���� ����� ��� ����������
  upvar $CVS lst ;

# ������������� ���������� � ��
  database db $tns $usr $pwd
#db set autocommit off

# ������������� ����
# �� ��������� = BASE_EXT_CONNECT_OIK CONNECT => SBOR_STAND_READ = (SELECT = da_dev_desc )  BASE_STAND_READ
  if {$usr!="rsduadmin"} {
    db "SET ROLE SBOR_STAND_READ , BASE_STAND_READ"
    db "select * from session_roles"
  }

# �������� id_proto_point + id_dev  
  set id_proto_point -1 ;
  set id_dev -1 ;
  set str2 "select * from da_dev_desc where id=%ld order by id"
  set res2 [ format $str2 $id_parent ]
  set y2 [ db $res2 ]
  foreach {y} $y2 {
    set id_proto_point [lindex $y 1] ;
	set id_dev [lindex $y 2] ;
  }  
  
  if {$id_dev<0} {  puts " \n\n id_dev====$id_dev \n\n" ;  return -1; }
  if {$id_proto_point<0} {  puts " \n\n id_proto_point====$id_proto_point \n\n" ;  return -1; }

# �������� id_proto_point
  set str3 "select id from da_proto_desc where id_parent=$id_proto_point" ; # where id_parent=%ld
  set y3 [ db $str3 ]
  foreach {y} $y3 {
    set id_proto_point [lindex $y 0] ;
  } 
  
# �������� max ID
  set maxId 0
  set str1 "select max(id) from da_dev_desc" ; #
  set y1 [ db $str1 ]
  foreach {y} $y1 {
    set maxId [lindex $y 0] ;
  }  
  puts " \n max(Id)=$maxId \n" ;
  
  if {$saveFile==1} { set df [ open $fsql "w+"] ; }
  
# ��������� ������ ��� �������
  for {set ind 0} {$ind<[llength $lst]} {incr ind} {
  
    set maxId [ expr $maxId+1 ] 
  
    set s0 [lindex $lst $ind ] ;
    set pl [ split $s0 ";" ]
	if {[llength $pl]<3} { continue ; }
	set name [lindex $pl 0 ] ;
	set cvalif [lindex $pl 1 ] ;
	set tcode [lindex $pl 2 ] ;

	# ID_GTOPT = sys_gtopt.id
	# 1 = ���������� ����������
	# 8 = ���������� �������
	set ID_GTOPT 1
	if {0==[string compare -nocase $tcode "��"]} { set ID_GTOPT 8 ; }
	
	# ID_TYPE = sys_dtype.id
	# 405 - ������� ����������
	# 7 - ����������
	# 5 - ���
	# 6 - ���������� �������� Q
	# 8 - �������� �������� P
	# --------------------------
	# 406 - ������� �������
	# 
	# 
	set ID_TYPE 0
	if {$ID_GTOPT==1} {
	   set ID_TYPE 405
	   if {[regexp "Ia" $name]} { set ID_TYPE 5 }
	   if {[regexp "Ib" $name]} { set ID_TYPE 5 }
	   if {[regexp "Ic" $name]} { set ID_TYPE 5 }
	   if {[regexp "Ua" $name]} { set ID_TYPE 7 }
	   if {[regexp "Ub" $name]} { set ID_TYPE 7 }
	   if {[regexp "Uc" $name]} { set ID_TYPE 7 }
	   if {[regexp "Uab" $name]} { set ID_TYPE 7 }
	   if {[regexp "Ubc" $name]} { set ID_TYPE 7 }
	   if {[regexp "Uca" $name]} { set ID_TYPE 7 }
	   if {[regexp "P" $name]} { set ID_TYPE 8 }
	   if {[regexp "Q" $name]} { set ID_TYPE 6 }
	}
    if {$ID_GTOPT==8} {
	   set ID_TYPE 406
    }	

	set strSQL "Insert into DA_DEV_DESC (ID, ID_PROTO_POINT, ID_DEV, ID_PARENT, NAME, CVALIF, ID_TYPE, ID_GTOPT, ATTR_NAME) \
        Values  (${maxId}, ${id_proto_point}, ${id_dev}, ${id_parent}, '${name}', ${cvalif}, ${ID_TYPE}, ${ID_GTOPT}, NULL);"
	if {$saveFile==1} { puts $df $strSQL ; } 
	if {$saveFile>1} { db $strSQL ; }
	puts "${strSQL}"
	
  }  
 
  if {$saveFile==1} {  flush $df ; close $df  ; }
 # ��������� ���������� � ��
  if {$saveFile>1} {  db commit ; }
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
  set nameFile "da_dev2.sql" ; # ��� ����� ��� ���������� ����������
  set nameFileCSV "�����1.csv" ; # ��� ����� ��� ���������� ����������
  set saveFile 1 ; # 1-������ � ����-sql. ��� 2-commit � ���� ; 0- ������
#=============================================

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nstart = $t1\n"

  set ls {} ; #[ list ]
  
  # ��������� �������� �����
  set path [info script]
  set path [ file normalize $path ]
  set dirname [ file dirname $path ]
  set fsql [file join $dirname $nameFile ]
  set f0 [file join $dirname $nameFileCSV ]
  set f [ file nativename $f0 ]
  # ��������� �� ���������� � ����
  set fd [ open $f "r"]
  while {![eof $fd]} {
	 gets $fd data
	 set ls [linsert $ls end "${data}" ] ;
  }
  close $fd
  
  set id_parent 5008769  
  set ret [ da_dev2 $tns $usr $pwd $fsql ls $id_parent $saveFile]

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nend = $t1"

  return 0 ;
}


daDevMain











