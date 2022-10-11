#!/bin/bash

# ver 11/10/2022

# folders
EMA_LOGS1=(
/home/ema
/var/log/ema
/var/log/mysql
/var/log/apache2
/var/isms
/usr/share/ema
/usr/bin/isms
/home/www-data/www/htdocs/WASUTP/config
/home/www-data/www/htdocs/WASUTP/public/resource
/etc/ema
/etc/php5
/etc/mysql
/etc/apache2
/etc/nginx
/usr/lib64/nginx/modules
/etc/ntp
/etc/vmware
/etc/sysconfig
/etc/nagios
/etc/unixODBC
/etc/unixODBC_23
/etc/sysconfig/network
/usr/lib/nagios/plugins
/usr/local/nagios/etc
/usr/lib/oracle/11.2/client
/usr/lib/oracle/11.2/client64
/opt/oracle/instantclient_11_2
/etc/rabbitmq
/var/log/rabbitmq
/var/log/mongodb
# /var/ema/coredumps
/var/www/hde.conf
/var/www/hde.app/log
);


# files
EMA_LOGS2=(
/etc/init.d/ema_autoload
/etc/ftpusers
/etc/fstab
#/etc/HOSTNAME
/etc/hostname
/etc/hosts
/etc/modprobe.conf
/etc/modprobe.d/unsupported-modules
/etc/ntp.conf
/etc/oratab
/etc/resolv.conf
/etc/sudoers
/etc/SuSE-release
/etc/os-release
/etc/sysctl.conf
/etc/vsftpd.conf
/etc/profile.d/oracle.sh
/etc/my.conf
/etc/cron.d/isms_autobackup
/etc/rc.d/boot.local
/etc/rc.d/rc.local
/etc/conf.d/local.start
/etc/xinetd.d/nrpe
/etc/logrotate.d/ema
/etc/ld.so.conf
/var/log/mail
/var/log/ntp
/var/log/auth.log
/var/log/daemon.log
/var/log/mysql.err
/var/log/mysql.log
/var/log/messages
/var/log/messages.1
/var/log/dmesg
/var/log/dmesg.1
/var/log/syslog
/var/log/syslog.1
/var/log/auth.log
/var/log/boot.log
/root/LinuxRT/trunk/rsdu.config
/usr/share/doc/isms/ReleaseNotesiSMS.txt
/usr/lib/npreal2/driver/npreal2d.cf
/etc/ld.so.conf.d/oracle.conf
/opt/APC/PowerChute/group1/m11.cfg
/opt/APC/PowerChute/group1/m11.bak
/opt/APC/PowerChute/group1/pcnsconfig.ini
/opt/APC/PowerChute/group1/pcnsconfig.ini.bak
/opt/APC/PowerChute/group1/java.cfg
/opt/APC/PowerChute/group1/comps.m11
/opt/APC/PowerChute/group1/shutdownerlets.m11
/opt/APC/PowerChute/group1/psaggregator.m11
/etc/mongod.conf
/var/www/hde.conf/nginx.conf
/etc/logrotate.d/rabbitmq-server
/etc/logrotate.d/ema
/etc/cron.d/ema_time
);


DIR="/tmp"
nm="ema"


EMA_file_exists ()
{
  obj=$1
  ret=1
  if [ ! -f $obj ]
  then
     ret=0
  fi
  return $ret
}


EMA_dir_exists ()
{
  obj=$1
  ret=1
  if [ ! -d $obj ]
  then
     ret=0
  fi
  return $ret
}


EMA_logs_dir ()
{
  DIR=$(pwd)
  hn=$(printenv HOSTNAME)
  if [ ! -n "$hn" ]
  then
     hn=$(hostname)
  fi
  usr=$(printenv LOGNAME)

  nm=${nm}_${hn}_$(date +%Y%m%d-%H%M%S)

  DIR=${DIR}/${nm}

  if [[ ! -d "$DIR" && ! -L "$DIR" ]] ; then
    # создать папку, только если ее не было и не было символической ссылки
    mkdir "$DIR" 2> /dev/null
  fi

  echo $DIR
}


EMA_logs_env ()
{
  echo "ENV"
  query=$(env)
  echo -e -n "$query" > ${DIR}/env.log
}


EMA_logs_list ()
{

  idx=0
  while test $idx -lt ${#EMA_LOGS1[@]}; do
    if [ -n "${EMA_LOGS1[$idx]}" ]; then
      src=${EMA_LOGS1[$idx]}
      desc=$DIR
      EMA_dir_exists ${src}
      if [ "$?" -eq 1 ]
      then
         mkdir -p "${DIR}${src}" 2> /dev/null
         cp -a ${src}/* ${desc}${src}
      fi
    fi
    let idx=idx+1
  done

  idx=0
  while test $idx -lt ${#EMA_LOGS2[@]}; do
    if [ -n "${EMA_LOGS2[$idx]}" ]; then
      src=${EMA_LOGS2[$idx]}
      desc=$DIR
      EMA_file_exists ${src}
      if [ "$?" -eq 1 ]
      then
         cp -a --parents ${src} ${desc}
      fi
    fi
    let idx=idx+1
  done

}


EMA_logs_stat ()
{
  echo "STAT"

  n=${DIR}/stat.log

  echo -e  " " > "$n"

  cmd1="date"
  echo -e  "\n$cmd1" >> "$n"
  $cmd1 >> "$n"

  cmd1="cal"
  echo -e  "\n" >> $n
  $cmd1 >> $n

  cmd1="/etc/timezone"
  echo -e  "\ncat $cmd1" >> $n
  EMA_file_exists $cmd1
  if [ "$?" -eq 1 ]
  then
    cat $cmd1 >> $n
  fi

  cmd1="w"
  echo -e  "\n$cmd1" >> $n
  $cmd1 >> $n

  cmd1="uptime"
  echo -e  "\n$cmd1" >> $n
  $cmd1 >> $n

  cmd1="uname -a"
  echo -e  "\n$cmd1" >> $n
  $cmd1 >> $n

  cmd1="lsb_release -a"
  echo -e  "\n$cmd1" >> $n
  $cmd1  >> $n

  cmd1="/proc/version"
  echo -e  "\n$cmd1" >> $n
  EMA_file_exists $cmd1
  if [ "$?" -eq 1 ]
  then
    cat $cmd1 >> $n
  fi

  cmd1="/etc/SuSE-release"
  echo -e  "\n$cmd1" >> $n
  EMA_file_exists $cmd1
  if [ "$?" -eq 1 ]
  then
    cat $cmd1 >> $n
  fi

  cmd1="/etc/redhat-release"
  echo -e  "\n$cmd1" >> $n
  EMA_file_exists $cmd1
  if [ "$?" -eq 1 ]
  then
    cat $cmd1 >> $n
  fi

  cmd1="df -h"
  echo -e  "\n$cmd1" >> $n
  $cmd1 >> $n
  #$cmd1 /dev/shm/ >> $n

  cmd1="free -m -l -t"
  echo -e  "\n$cmd1" >> $n
  $cmd1 >> $n

  cmd1="/proc/meminfo"
  echo -e  "\ncat $cmd1" >> $n
  EMA_file_exists $cmd1
  if [ "$?" -eq 1 ]
  then
    cat $cmd1 >> $n
  fi

  cmd1="netstat -netulap"
  echo -e  "\n$cmd1" >> $n
  $cmd1 >> $n

  cmd1="ifconfig -a"
  echo -e  "\n$cmd1" >> $n
  $cmd1 >> $n

  cmd1="route -n"
  echo -e  "\n$cmd1" >> $n
  $cmd1 >> $n

  cmd1="service ntp status"
  echo -e  "\n$cmd1" >> $n
  $cmd1 >> $n

  cmd1="service ntpd status"
  echo -e  "\n$cmd1" >> $n
  $cmd1 >> $n

  cmd1="ntpq -np -4"
  echo -e  "\n$cmd1" >> $n
  $cmd1 >> $n

  cmd1="/etc/resolv.conf"
  echo -e  "\ncat $cmd1" >> $n
  EMA_file_exists
  if [ "$?" -eq 1 ]
  then
    cat $cmd1 >> $n
  fi

  cmd1="crontab -l"
  echo -e  "\n$cmd1" >> $n
  $cmd1 >> $n

  cmd1="lsmod"
  echo -e  "\n$cmd1" >> $n
  $cmd1 >> $n

  cmd1="NetWorker-nsrexecd"
  echo -e  "\n$cmd1" >> $n
  ps -A | grep nsrexecd >> $n

  cmd1="last reboot"
  echo -e  "\n$cmd1" >> $n
  $cmd1 >> $n

  cmd1="dpkg -l | grep --regexp=isms|mysql|apache|rsdu"
  echo -e  "\n" >> $n
  $cmd1 >> $n
  dpkg --get-selections | grep isms >> $n
  dpkg --get-selections | grep mysql >> $n
  dpkg --get-selections | grep apache >> $n
  dpkg --get-selections | grep rsdu >> $n

  cmd1="rpm -qa"
  echo -e  "\n$cmd1" >> $n
  $cmd1 >> $n

  echo -e  " " >> $n

}


EMA_logs_mysql ()
{
  echo "MySQL"

  n=${DIR}/mysql.log

  echo -e  " \n" > "$n"

  ## Constants
  mysql_login='root'
  mysql_pass='passme'
  mysql_host='localhost'
  mysql_db='rsduadmin'

  echo -e  "mysql_login=$mysql_login" >> "$n"
  echo -e  "mysql_pass=$mysql_pass" >> "$n"
  echo -e  "mysql_host=$mysql_host" >> "$n"
  echo -e  "mysql_db=$mysql_db" >> "$n"
  echo -e  "\n =>" >> "$n"

  which mysql
  if [ "$?" -eq 1 ]
  then
    echo -e  "======== not exist mysql" >> "$n"
    return 0
  fi

  sql="status;"
  echo -e  "\n\n $sql =>" >> "$n"
  mysql -u "$mysql_login" -p"$mysql_pass"  -e "$sql" >> "$n"

  sql="SHOW STATUS;"
  echo -e  "\n\n $sql =>" >> "$n"
  RES=`mysql -u "$mysql_login" -p"$mysql_pass" "$mysql_db" -e "$sql" `
  printf "$RES" >> "$n"

  sql="SHOW PROCESSLIST;"
  echo -e  "\n\n $sql =>" >> "$n"
  RES=`mysql -u "$mysql_login" -p"$mysql_pass" "$mysql_db" -e "$sql" `
  printf "$RES" >> "$n"

  sql="SHOW VARIABLES;"
  echo -e  "\n\n $sql =>" >> "$n"
  RES=`mysql -u "$mysql_login" -p"$mysql_pass" "$mysql_db" -e "$sql" `
  printf "$RES" >> "$n"

  sql="SHOW TABLE STATUS;"
  echo -e  "\n\n $sql =>" >> "$n"
  RES=`mysql -u "$mysql_login" -p"$mysql_pass" "$mysql_db" -e "$sql" `
  printf "$RES" >> "$n"

  cmd1="/usr/bin/isms_backup_config.sh"
  echo -e  "\n\n $cmd1 =>" >> "$n"
  EMA_file_exists $cmd1
  if [ "$?" -eq 1 ]
  then
     $cmd1 "${DIR}/isms_db.tar.bz2" >> $n
  fi

}


EMA_logs_oracle ()
{
  echo "ORACLE"

  n=${DIR}/oracle.log

  echo -e  " " > "$n"

  nl=$(printenv NLS_LANG)
  echo -e  "\nNLS_LANG=$nl" >> $n
  nlc=$(printenv NLS_NUMERIC_CHARACTERS)
  echo -e  "\nNLS_NUMERIC_CHARACTERS=$nlc" >> $n
  ndt=$(printenv NLS_DATE_FORMAT)
  echo -e  "\nNLS_DATE_FORMAT=$ndt" >> $n

  ##ORACLE_BASE=/opt/oracle
  ob=$(printenv ORACLE_BASE)
  echo -e  "\nORACLE_BASE=$ob" >> $n

  ##ORACLE_HOME=$ORACLE_BASE/product/11g
  oh=$(printenv ORACLE_HOME)
  echo -e  "\nORACLE_HOME=$oh" >> $n

  ##ORACLE_SID=rsdu
  os=$(printenv ORACLE_SID)
  echo -e  "\nORACLE_SID=$os" >> $n
  ##ORA_CRS_HOME=$ORACLE_BASE/product/crs
  och=$(printenv ORA_CRS_HOME)
  echo -e  "\nORA_CRS_HOME=$och" >> $n

  echo -e  "\ncrontab -u oracle -l" >> $n
  crontab -u oracle -l >> $n

  cmd1="find $ob -name alert_*.log"
  echo -e  "\n$cmd1"  >> $n
  arr=$($cmd1)
  echo -e  "=\n${arr[@]}"  >> $n
  for f in "${arr[@]}"
  do
    EMA_file_exists $f
    if [ "$?" -eq 1 ]
    then
       cp -a --parents ${f} ${DIR}
    fi
  done

  cmd1="find $ob -name *.ora"
  echo -e  "\n$cmd1"  >> $n
  arr=$($cmd1)
  echo -e  "=\n${arr[@]}"  >> $n
  for f in "${arr[@]}"
  do
    EMA_file_exists $f
    if [ "$?" -eq 1 ]
    then
       cp -a --parents ${f} ${DIR}
    fi
  done

  ob1=$ob/backup/hist_table_data
  EMA_dir_exists "$ob1"
  if [ "$?" -eq 0 ]
  then
    echo -e  "\n $ob1 - not exist"  >> $n
  fi

  ob2=$ob/backup/script
  arr=$(find $ob2 -maxdepth 1  -name "*.sh" -o -name "*.log")
  echo -e  "=\n${arr[@]}"  >> $n
  for f in "${arr[@]}"
  do
    EMA_file_exists $f
    if [ "$?" -eq 1 ]
    then
       cp -a --parents ${f} ${DIR}
    fi
  done

}


EMA_logs_ema ()
{
  echo "EMA"

  n=${DIR}/ema.log

  ltime -l >> $n
  ema cfg >> $n

  echo  "----------DebugManage----------" >> $n
  EMA_file_exists /usr/bin/DebugManage
  if [ "$?" -eq 1 ]
  then
    cfg_file=/etc/ema/ema.cfg
    EMA_file_exists $cfg_file
    if [ "$?" -eq 1 ]
    then
     while read _line
     do
       ema_process=`echo $_line | cut -f 1 -d ' ' | grep -v "sleep" | grep -v "^;" | grep -v "^//" | grep -v "^#"`
       if [ -n "$ema_process" ]
       then
          /usr/bin/DebugManage $ema_process >> $n
       fi
     done < $cfg_file
    fi

    cfg_file=/etc/ema/ema.conf
    EMA_file_exists $cfg_file
    if [ "$?" -eq 1 ]
    then
     arr=$(ema cfg)
     #echo -e $arr
     #while read _line
     #do
     #  ema_process=`echo $_line | cut -f 1 -d ' ' | grep -v "sleep" | grep -v "^;" | grep -v "^//" | grep -v "^#" | grep "\[*\]" `
     #  a=${ema_process//"["}
     #  ema_process=${a//"]"}
     #  if [ -n "$ema_process" ]
     #  then
     #      /usr/bin/DebugManage $ema_process >> $n
     #  fi
     #done < $cfg_file
    fi

  fi

  ema version >> $n
  ema revision >> $n
  ema mem >> $n
  ema status >> $n

  hn=$(printenv HOSTNAME)
  if [ ! -n "$hn" ]
  then
    hn=$(hostname)
  fi

  ema_conf="ema_conf"
  ema_conf=${ema_conf}_${hn}
  z=$(date +%Y%m%d)
  ema_conf="${ema_conf}_${z}.tar.bz2"
  ema backup "${DIR}/${ema_conf}" >> $n
}


ShowUsage()
{
  echo "emalogs <command>"

  echo "Commands:"
  echo "  -."
  echo "  --"

}


EMA_main ()
{
  EMA_logs_dir

  EMA_logs_env
  EMA_logs_list
  EMA_logs_stat
  EMA_logs_ema
  #EMA_logs_mysql
  EMA_logs_oracle

  echo -n "${reset}"
}


EMA_main
exit 0
