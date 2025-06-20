#!/usr/bin/env tclsh

#
#What:
# /home/ema/*
# /retro/*
# /etc/ema/*
#      ftpusers
#      fstab
#      HOSTNAME
#      hosts
#      ntp.conf
#      oratab
#      sudoers
#      SuSE-release
#      sysctl.conf
#      vsftpd.conf
#      profile.d/oracle.sh
#      sysconfig/oracle
# /var/log/ema/*
# /var/log/messages
# /var/log/mail
# /var/log/ntp
# /root/LinuxRT/trunk/rsdu.config
# $TNS_ADMIN/tnsnames.ora
# $ORACLE_BASE/backup/script
#
#When:
# /root/ema_<host>_<date>
#

global env


set EMA_LOGS [ list \
/home/ema/* \
/etc/ema/* \
/etc/ftpusers \
/etc/fstab \
/etc/HOSTNAME \
/etc/hosts \
/etc/ntp.conf \
/etc/oratab \
/etc/sudoers \
/etc/SuSE-release \
/etc/sysctl.conf \
/etc/vsftpd.conf \
/etc/profile.d/oracle.sh \
/etc/sysconfig/oracle \
/var/log/ema/* \
/var/log/messages \
/var/log/mail \
/var/log/ntp \
/root/LinuxRT/trunk/rsdu.config
]

if {[info exists env(TNS_ADMIN)]} {
  set tns [file join $env(TNS_ADMIN) ] ; # "tnsnames.ora"
  lappend EMA_LOGS $tns
}

if {[info exists env(ORACLE_BASE)]} {
  set backup [file join $env(ORACLE_BASE) "backup/script" ] ; #
  lappend EMA_LOGS $backup
}




#===========================================
proc EMA_logs_dir { } {
#===========================================

  global env
  global EMA_LOGS

  set dir "/tmp"
  set nm "ema"

  set dir [pwd]  
  
  #if {[info exists env(HOME)]} {
  #  set dir "$env(HOME)"
  #}

  if {[info exists env(HOST)]} {
    set nm "${nm}_$env(HOST)"
  }

  set z [clock format [clock seconds] -format %Y%m%d-%H%M%S]
  
  set dir "${dir}/${nm}_${z}"

  if {[file exists $dir ]} {
    puts "Folder $dir already exists\n break script..."
    return $dir
  }

  file mkdir $dir

  return $dir
}


#===========================================
proc EMA_logs_list { dir } {
#===========================================
  global env
  global EMA_LOGS

  foreach name $EMA_LOGS {

    puts -nonewline "$name  "

    set fn1 [ glob -nocomplain  $name ]
    set l [llength $fn1]

    if {$l==1} {
       set ob [ lindex $fn1 0 ]
       set target [ file dirname $dir$ob ]
       if {0==[file exists $target ]} {
          file mkdir $target
       }
       if {[file exists $ob ]} {
          catch { file copy -force -- $ob $target }
       }
    }

    if {$l>1} {
      foreach ob $fn1 {
        set target [ file dirname $dir$ob ]
        if {0==[file exists $target ]} {
             file mkdir $target
        }
        if {[file isdirectory $ob]} { set ob [ glob -nocomplain -- "$ob/*" ] }
        foreach obx $ob {
          if {[file isfile $obx]} {
            #puts "${obx}=${dir}"
            if {[file exists $ob ]} {
               catch { file copy -force -- $obx $target }
            }
          }
        }
      }
    }

  }

  puts " "

}


#===========================================
proc EMA_logs_env { dir } {
#===========================================
  global env

  puts "ENV"

  set nmlg "${dir}/env.log"
  set f [ open $nmlg "w" ]
  foreach id [ array names env ] { puts $f "$id=$env($id)" }
  flush $f
  close $f

}


#===========================================
proc EMA_logs_stat { dir } {
#===========================================
  global env

  puts "STAT"

  set nmlg "${dir}/stat.log"

  if {[info exists env(USER)]} {
    exec echo -e  "\nenv(USER)=$env(USER)" >> $nmlg
  }

  exec echo -e  "\ndate" >> $nmlg
  exec date >> $nmlg

  exec echo -e  "\ncat /etc/timezone" >> $nmlg
  catch { exec cat /etc/timezone >> $nmlg }

  exec echo -e  "\nuptime" >> $nmlg
  exec uptime >> $nmlg

  exec echo -e  "\nuname -a" >> $nmlg
  exec uname -a >> $nmlg

  exec echo -e  "\ndf -h" >> $nmlg
  exec df -h >> $nmlg
  #exec df -h /dev/shm/ >> $nmlg

  exec echo -e  "\nfree -m -l -t" >> $nmlg
  exec free -m -l -t >> $nmlg

  exec echo -e  "\ncat /proc/meminfo" >> $nmlg
  exec cat /proc/meminfo >> $nmlg

  exec echo -e  "\nnetstat -netulap" >> $nmlg
  exec netstat -netulap >> $nmlg

  exec echo -e  "\nifconfig -a" >> $nmlg
  catch { exec ifconfig -a >> $nmlg }

  exec echo -e  "\nroute -n" >> $nmlg
  catch { exec route -n >> $nmlg }

  exec echo -e  "\nservice ntp status" >> $nmlg
  catch { exec service ntp status >> $nmlg }

  exec echo -e  "\nntpq -np" >> $nmlg
  catch { exec ntpq -np >> $nmlg }

  exec echo -e  "\ncat /etc/resolv.conf" >> $nmlg
  catch { exec cat /etc/resolv.conf >> $nmlg }

  exec echo -e  "\ncrontab -l" >> $nmlg
  exec crontab -l >> $nmlg

  exec echo -e  "\nlsmod" >> $nmlg
  catch { exec lsmod >> $nmlg }

  exec echo -e  "\nNetWorker-nsrexecd" >> $nmlg
  catch { exec ps -A | grep nsrexecd >> $nmlg }

  exec echo -e  "\nlast reboot" >> $nmlg
  catch { exec last reboot >> $nmlg }

  exec echo -e  "\ndpkg -l | grep --regexp=isms|mysql|apache|rsdu" >> $nmlg
  catch { exec dpkg -l | grep --regexp=isms|mysql|apache|rsdu >> $nmlg }

  exec echo -e  "\nrpm -qa" >> $nmlg
  catch { exec rpm -qa >> $nmlg }


  exec echo -e  " " >> $nmlg

}


#===========================================
proc EMA_logs_oracle { dir } {
#===========================================
  global env

  puts "ORACLE"

  set nmlg "${dir}/oracle.log"


  # /opt/oracle
  # /opt/oracle/backup
  # /opt/oracle/admin
  # find /opt/oracle -name "alert_*.log"

#  set name "find /opt/oracle -name \"alert_*.log\" "

#  set fn1 [ glob -nocomplain -directory /opt/oracle  -types f -- alert_*.log ]
#  set l [llength $fn1]

#  exec echo -e  "\n $fn1" >> $nmlg

#glob -nocomplain -path "/opt/oracle/*"  "alert_*.log"
#glob -nocomplain -path "/opt/oracle"  "*.*"

#glob -nocomplain "/opt/oracle/*"

}



#===========================================
proc EMA_logs_mysql { dir } {
#===========================================
  global env

  puts "MySQL"

  set nmlg "${dir}/mysql.log"

}


#===========================================
proc EMA_logs_ema { dir } {
#===========================================
  global env
  
  puts "EMA"

  set nmlg "${dir}/ema.log"
  catch { exec ltime -l >> $nmlg }
  catch { exec ema cfg >> $nmlg }


  set chan0 [open $nmlg "a+" ]
  puts $chan0 "----------DebugManage----------"
  close $chan0
  if {[file exists /usr/bin/DebugManage ]} {
    set fn /etc/ema/ema.cfg
    if {[file exists $fn ]} {
      set chan [open $fn "r" ]
      while {[gets $chan line] >= 0} {
          set l [ split $line " " ]
          set s [ lindex $l 0 ]
          if {$s!="sleep"} {
            catch { exec /usr/bin/DebugManage $s >> $nmlg }
          }
      }
      close $chan
    }
    set fn /etc/ema/ema.conf
    if {[file exists $fn ]} {
      set chan [open $fn "r" ]
      while {[gets $chan line] >= 0} {
          set l1 [ string length $line ]
          set line2 [ string trim $line "\[\]" ]
          set l2 [ string length $line2 ]
          if {$l1!=$l2} {
            catch { exec /usr/bin/DebugManage $line2 >> $nmlg }
          }
      }
      close $chan
    }
  }

  catch { exec ema version >> $nmlg }
  catch { exec ema revision >> $nmlg }
  catch { exec ema mem >> $nmlg }
  catch { exec ema status >> $nmlg }

  set ema_conf "ema_conf"
  if {[info exists env(HOST)]} {
    set ema_conf "${ema_conf}_$env(HOST)"
  }
  set z [clock format [clock seconds] -format %Y%m%d]
  set ema_conf "${ema_conf}_${z}.tar.bz2"

  catch { exec ema backup $dir/$ema_conf >> $nmlg }

  
}



#===========================================
proc EMA_logs { } {
#===========================================
  global env
  global EMA_LOGS

  set dir [ EMA_logs_dir ]
  
  EMA_logs_list $dir 
  EMA_logs_env  $dir
  EMA_logs_stat $dir
  EMA_logs_oracle $dir
  EMA_logs_mysql $dir
  EMA_logs_ema $dir

  puts "ready." 

}


EMA_logs