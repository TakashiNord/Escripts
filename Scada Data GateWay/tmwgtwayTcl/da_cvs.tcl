#=============================================
#
#
#
#=============================================

# �������� ������ ��� ����� ��� ��������
set f "da_dev.tcl"
set paths [info script]
set paths [ file normalize $paths ]
set dirname [ file dirname $paths ]
set f0 [file join $dirname $f ]
set f [ file nativename $f0 ]
# ��������� ��� �� ����� F
source $f

#=============================================
proc tmwgtwayMain { } {
#=============================================
global   tcl_platform
#========================== ������ ���������
  set tns "rsdu2"
  set usr "rsduadmin" ; #  admin  nov_ema
  set pwd "passme" ; # passme  qwertyqaz
  set crn 1 ; # 0 - ������� ����� ��� � ��, ���� - ������ ��\��
  set saveFile 1 ; # ������ � ����
  set nameFile "tmwgtway_rsdu2.txt" ; # ��� ����� ��� ���������� ����������
#============================================

  set t1 [ clock format [ clock seconds ] -format "%T" ]
  puts "\nstart = $t1\n"

  if { $tcl_platform(platform) == "unix" } {
       ;#
  } else {
       ;#
  }
  
  set ls {};
  tmwgtway $tns $usr $pwd $crn ls

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


tmwgtwayMain











