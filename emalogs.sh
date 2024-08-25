#!/bin/bash

# ver 07/12/2023

# folders
EMA_LOGS1=(
/home/ema
/home/www-data/www/htdocs/WASUTP/config
/home/www-data/www/htdocs/WASUTP/public/resource
#/home/cassandra/../conf
/etc/ema
/etc/php5
/etc/mysql
/etc/apache2
/etc/nginx
/etc/ntp
/etc/ld.so.conf.d
/etc/vmware
/etc/sysconfig
/etc/nagios
/etc/unixODBC
/etc/unixODBC_23
/etc/sysconfig/network
/etc/rabbitmq
/etc/keepalived
/usr/share/ema
/usr/bin/isms
/usr/lib/nagios/plugins
/usr/local/nagios/etc
#/usr/lib64/nginx/modules
#/usr/lib/oracle/11.2/client
#/usr/lib/oracle/11.2/client64
#/opt/oracle/instantclient_11_2
#/opt/oracle/instantclient_11_4
#/var/log/rabbitmq
#/var/log/mongodb
/var/www/hde.conf
/var/www/hde.app/log
/var/log/ema
/var/log/mysql
/var/log/apache2
/var/isms
/root/.ssh
);


# files
EMA_LOGS2=(
/etc/init.d/ema_autoload
/etc/ftpusers
/etc/fstab
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
/etc/profile.d/oracle-xe.sh
/etc/my.conf
/etc/mongod.conf
/etc/cron.d/isms_autobackup
/etc/cron.d/ema_time
/etc/rc.d/boot.local
/etc/rc.d/rc.local
/etc/conf.d/local.start
/etc/xinetd.d/nrpe
/etc/logrotate.d/ema
/etc/logrotate.d/rabbitmq-server
/etc/logrotate.d/nginx
/etc/ld.so.conf
#/etc/ld.so.conf.d/oracle.conf
/etc/security/limits.conf
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
/var/log/cassandra/debug.log
/var/www/hde.conf/nginx.conf
/root/LinuxRT/trunk/rsdu.config
/opt/APC/PowerChute/group1/m11.cfg
/opt/APC/PowerChute/group1/m11.bak
/opt/APC/PowerChute/group1/pcnsconfig.ini
/opt/APC/PowerChute/group1/pcnsconfig.ini.bak
/opt/APC/PowerChute/group1/java.cfg
/opt/APC/PowerChute/group1/comps.m11
/opt/APC/PowerChute/group1/shutdownerlets.m11
/opt/APC/PowerChute/group1/psaggregator.m11
/usr/share/doc/isms/ReleaseNotesiSMS.txt
/usr/lib/npreal2/driver/npreal2d.cf
);


DIR="/tmp"
nm="ema"


function EMA_file_exists ( )
{
  obj=$1
  ret=1
  if [ ! -f $obj ]
  then
     ret=0
  fi
  return $ret
}


function EMA_dir_exists ( )
{
  obj=$1
  ret=1
  if [ ! -d $obj ]
  then
     ret=0
  fi
  return $ret
}


function EMA_logs_dir ( )
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
    # exlude link
    mkdir "$DIR" 2> /dev/null
  fi

  echo $DIR
}


function EMA_logs_env ( )
{
  echo "ENV"

  DIR=$1

  query=$(env)
  echo -e -n "$query" > ${DIR}/env.log

  return 0
}


function EMA_logs_list ( )
{
  DIR=$1

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

  return 0
}


function EMA_logs_stat ( )
{
  echo "STAT"

  DIR=$1

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

  cmd1="/etc/issue"
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

  cmd1="ip addr"
  echo -e  "\n$cmd1" >> $n
  $cmd1 >> $n

  cmd1="route -n"
  echo -e  "\n$cmd1" >> $n
  $cmd1 >> $n

  cmd1="ip -d route"
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

  echo -e  "\n------DEBIAN" >> $n

  cmd1="dpkg -l | grep --regexp=isms|mysql|apache|rsdu"
  echo -e  "\n" >> $n
  $cmd1 >> $n

  cmd1="dpkg --get-selections | grep ...... "
  echo -e  "\n$cmd1" >> $n
  echo -e  "\n" >> $n
  dpkg --get-selections | grep isms >> $n
  dpkg --get-selections | grep mysql >> $n
  dpkg --get-selections | grep apache >> $n
  dpkg --get-selections | grep rsdu >> $n

  cmd1="dpkg --get-selections | grep -v "deinstall" | awk '{ print $1 }'"
  echo -e  "\n$cmd1" >> $n
  echo -e  "\n" >> $n
  dpkg --get-selections | grep -v "deinstall" | awk '{ print $1 }' >> $n


  echo -e  "\n------SUSE" >> $n

  cmd1="rpm -qa"
  echo -e  "\n$cmd1" >> $n
  $cmd1 >> $n

  echo -e  " " >> $n

  return 0
}


function EMA_logs_mysql ( )
{
  echo "MySQL"

  DIR=$1

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

  return 0
}


function EMA_logs_oracle ( )
{
  echo "ORACLE"

  DIR=$1

  n=${DIR}/oracle.log

  echo -e  " " > "$n"

  echo -e  "\nid oracle" >> $n
  id oracle >> $n

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


  EMA_dir_exists "$ob"
  if [ "$?" -eq 1 ]
  then

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
    arr=$(find $ob2 -maxdepth 1 -type f -name "*.sh" -o -name "*.log" -o -name "*.sql" )
    echo -e  "=\n${arr[@]}"  >> $n
    for f in "${arr[@]}"
    do
      EMA_file_exists $f
      if [ "$?" -eq 1 ]
      then
         cp -a --parents ${f} ${DIR}
      fi
    done

    ob2=$ob/check
    arr=$(find $ob2 -maxdepth 1 -type f -name "*.sh" -o -name "*.log" -o -name "*.sql" )
    echo -e  "=\n${arr[@]}"  >> $n
    for f in "${arr[@]}"
    do
      EMA_file_exists $f
      if [ "$?" -eq 1 ]
      then
         cp -a --parents ${f} ${DIR}
      fi
    done

    ob2=$ob/backup/check
    arr=$(find $ob2 -maxdepth 1 -type f -name "*.sh" -o -name "*.log" -o -name "*.sql")
    echo -e  "=\n${arr[@]}"  >> $n
    for f in "${arr[@]}"
    do
      EMA_file_exists $f
      if [ "$?" -eq 1 ]
      then
         cp -a --parents ${f} ${DIR}
      fi
    done


  fi


  ob3=/usr/lib/oracle
  arr=$(find $ob3 -type f -name "tnsnames*.ora" -o -name "sqlnet*.ora")
  echo -e  "=\n${arr[@]}"  >> $n
  for f in "${arr[@]}"
  do
    EMA_file_exists $f
    if [ "$?" -eq 1 ]
    then
       cp -a --parents ${f} ${DIR}
    fi
  done

  ob3=/usr/lib64/oracle
  arr=$(find $ob3 -type f -name "tnsnames*.ora" -o -name "sqlnet*.ora")
  echo -e  "=\n${arr[@]}"  >> $n
  for f in "${arr[@]}"
  do
    EMA_file_exists $f
    if [ "$?" -eq 1 ]
    then
       cp -a --parents ${f} ${DIR}
    fi
  done


  ob3=/opt/oracle/instantclient
  arr=$(find /opt/oracle/instantclient_11_2 /opt/oracle/instantclient_11_4 -type f -name "tnsnames*.ora" -o -name "sqlnet*.ora")
  echo -e  "=\n${arr[@]}"  >> $n
  for f in "${arr[@]}"
  do
    EMA_file_exists $f
    if [ "$?" -eq 1 ]
    then
       cp -a --parents ${f} ${DIR}
    fi
  done



  ob3=/opt/oracle/.ssh
  echo -e  "\n $ob3 "  >> $n
  EMA_dir_exists "$ob3"
  if [ "$?" -eq 1 ]
  then
    mkdir -p "${DIR}${ob3}" 2> /dev/null
    cp -a ${ob3}/* ${DIR}${ob3}
  fi



  return 0
}


function EMA_logs_ema ( )
{
  echo "EMA"

  DIR=$1

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


  ob1=/var/ema/coredumps
  EMA_dir_exists "$ob1"
  if [ "$?" -eq 1 ]
  then
    darr=$(du -sh "$ob1")
    echo -e  "\nSIZE $ob1 = ${darr[@]}"  >> $n
  fi


  ob1=/retro
  EMA_dir_exists "$ob1"
  if [ "$?" -eq 1 ]
  then
    darr=$(du -sh "$ob1")
    echo -e  "\nSIZE $ob1 = ${darr[@]}"  >> $n
    arr=$(find $ob1 -type f)
    echo -e  "=\n${arr[@]}"  >> $n
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

  return 0
}



function EMA_logs_cass ( )
{
  echo "Cassandra"

  DIR=$1

  n=${DIR}/cass.log

  echo -e  " " > "$n"

  cmd1="java -version"
  echo -e  "\n$cmd1" >> $n
  $cmd1 2>> $n

  cmd1="python --version"
  echo -e  "\n$cmd1" >> $n
  $cmd1 2>> $n

  echo -e  "\nid cassandra" >> $n
  id cassandra >> $n

  cmd1="crontab -u cassandra -l"
  echo -e  "\n$cmd1" >> $n
  $cmd1 >> $n


  ob1=/home/cassandra

  EMA_dir_exists "$ob1"
  if [ "$?" -eq 1 ]
  then
    darr=$(du -sh "$ob1")
    echo -e  "\nSIZE $ob1 = ${darr[@]}"  >> $n
  fi
  echo -e  "\nCASS=$ob1" >> $n

  cmd1="find $ob1 -name conf* "
  echo -e  "\n$cmd1"  >> $n
  arr=$($cmd1)
  echo -e  "=\n${arr[@]}"  >> $n
  for f in "${arr[@]}"
  do
    cp -a --parents ${f} ${DIR}
  done


  ob1=/archive
  echo -e  "\n$ob1" >> $n

  EMA_dir_exists "$ob1"
  if [ "$?" -eq 1 ]
  then
    darr=$(du -sh "$ob1")
    echo -e  "\nSIZE $ob1 = ${darr[@]}"  >> $n
  fi

  cmd1="systemctl status cassandra"
  echo -e  "\n$cmd1" >> $n
  $cmd1 >> $n

  return 0
}


ShowUsage ( )
{
  echo "emalogs.sh <command>"

  echo "Commands:"
  echo "  -- no"
  echo "Output:"
  echo "  -- logs?info?file?dir?"

  return 0
}


EMA_main ( )
{
  d=$(EMA_logs_dir)

  EMA_dir_exists "$d"
  if [ "$?" -eq 0 ]
  then
    echo -e  "\n EMA_logs_dir - $d - not exist\n"
    exit 0
  fi

  EMA_logs_env "$d"
  EMA_logs_list "$d"
  EMA_logs_stat "$d"
  EMA_logs_ema  "$d"
  EMA_logs_oracle "$d"
  EMA_logs_cass "$d"
  #EMA_logs_mysql "$d"

  chmod -R 667 "$d"
  #chmod --silent -R a+rwx,u-x,g-x,o-x "$d"
  #chown -R root.users "$d"

  echo -n "${reset}"
}


EMA_main
exit 0
