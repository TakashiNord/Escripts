# Script to check time offset between local system and remote NTP servers
# All parameters should be saved in /etc/ema/ema_time.cfg file
# If time offset is greater than offset limit then opens connection to the signal system and
# send special signal for this
#
#!/bin/bash


ema_time () {
  #------ Config files ------
  cfg_file="/etc/ema/ema_time.cfg"

  if test ! -f $cfg_file
  then
    echo "Cannot be found the config file ($cfg_file)"
    exit 1
  fi

  if [ ! -e "/usr/bin/sgtest" ]
  then
      echo "Cannot be found /usr/bin/sgtest"
  fi

  if [ ! -e "/usr/bin/ltime" ]
  then
      echo "Cannot be found /usr/bin/ltime"
  fi

  #------ Print current date ------
  date

  #------ Read config file ------
  echo "Reading /etc/ema/ema_time.cfg file..."
  while read _line
  do
    # echo $_line
    if [ -n "`echo $_line | grep "time_offset=" | grep -v "^#" | grep -v "^;" | grep -v "^//"`" ]
    then
    offset_limit=$(
      echo $_line |
      awk '{
      idx = index($0, "time_offset=");
      if (idx != 0)
        print substr($0, idx + 12, length($0) - idx);
      }'
    )
    fi

    if [ -n "`echo $_line | grep "ss_user_id=" | grep -v "^#" | grep -v "^;" | grep -v "^//"`" ]
    then
    ss_user_id=$(
      echo $_line |
      awk '{
      idx = index($0, "ss_user_id=");
      if (idx != 0)
        print substr($0, idx + 11, length($0) - idx);
      }'
    )
    fi

    if [ -n "`echo $_line | grep "user_id=" | grep -v "^#" | grep -v "^;" | grep -v "^//"`" ]
    then
      user_id=$(
        echo $_line |
      awk '{
        idx = index($0, "user_id=");
        if (idx != 0)
      print substr($0, idx + 8, length($0) - idx);
      }'
    )
    fi

    if [ -n "`echo $_line | grep "ss_notimesrc_id=" | grep -v "^#" | grep -v "^;" | grep -v "^//"`" ]
    then
    ss_notimesrc_id=$(
      echo $_line |
      awk '{
      idx = index($0, "ss_notimesrc_id=");
      if (idx != 0)
      print substr($0, idx + 16, length($0) - idx);
      }'
    )
    fi

    if [ -n "`echo $_line | grep "ss_notimesrc_type=" | grep -v "^#" | grep -v "^;" | grep -v "^//"`" ]
    then
      ss_notimesrc_type=$(
        echo $_line |
      awk '{
        idx = index($0, "ss_notimesrc_type=");
        if (idx != 0)
      print substr($0, idx + 18, length($0) - idx);
      }'
    )
    fi

    if [ -n "`echo $_line | grep "ss_time_correct_id=" | grep -v "^#" | grep -v "^;" | grep -v "^//"`" ]
    then
    ss_time_correct_id=$(
      echo $_line |
      awk '{
        idx = index($0, "ss_time_correct_id=");
        if (idx != 0)
          print substr($0, idx + 19, length($0) - idx);
      }'
    )
    fi

    if [ -n "`echo $_line | grep "ss_time_correct_type=" | grep -v "^#" | grep -v "^;" | grep -v "^//"`" ]
    then
      ss_time_correct_type=$(
        echo $_line |
        awk '{
          idx = index($0, "ss_time_correct_type=");
          if (idx != 0)
            print substr($0, idx + 21, length($0) - idx);
        }'
      )
    fi

    if [ -n "`echo $_line | grep "ss_time_failed_id=" | grep -v "^#" | grep -v "^;" | grep -v "^//"`" ]
    then
    ss_time_failed_id=$(
      echo $_line |
      awk '{
      idx = index($0, "ss_time_failed_id=");
          if (idx != 0)
            print substr($0, idx + 18, length($0) - idx);
        }'
      )
    fi

    if [ -n "`echo $_line | grep "ss_time_failed_type=" | grep -v "^#" | grep -v "^;" | grep -v "^//"`" ]
    then
    ss_time_failed_type=$(
      echo $_line |
      awk '{
      idx = index($0, "ss_time_failed_type=");
      if (idx != 0)
        print substr($0, idx + 20, length($0) - idx);
       }'
    )
    fi

    if [ -n "`echo $_line | grep "was_time_failed=" | grep -v "^#" | grep -v "^;" | grep -v "^//"`" ]
    then
      was_time_failed=$(
        echo $_line |
        awk '{
          idx = index($0, "was_time_failed=");
          if (idx != 0)
            print substr($0, idx + 16, length($0) - idx);
         }'
       )
    fi
  done < $cfg_file


  #------ Checking parameters -------
  if [ ! -n "$offset_limit" ]
  then
    echo "time_offset...FAIL"
    exit 1
  fi

  if [ ! -n "$ss_user_id" ]
  then
    echo "ss_user_id...FAIL"
    exit 1
  fi

  if [ ! -n "$user_id" ]
  then
    echo "user_id...FAIL"
    exit 1
  fi

  if [ ! -n "$ss_notimesrc_id" ]
  then
    echo "ss_notimesrc_id...FAIL"
    exit 1
  fi

  if [ ! -n "$ss_notimesrc_type" ]
  then
    echo "ss_notimesrc_type...FAIL"
    exit 1
  fi

  if [ ! -n "$ss_time_correct_id" ]
  then
      echo "ss_time_correct_id...FAIL"
      exit 1
  fi

  if [ ! -n "$ss_time_correct_type" ]
  then
      echo "ss_time_correct_type...FAIL"
      exit 1
  fi

  if [ ! -n "$ss_time_failed_id" ]
  then
      echo "ss_time_failed_id...FAIL"
      exit 1
  fi

  if [ ! -n "$ss_time_failed_type" ]
  then
      echo "ss_time_failed_type...FAIL"
      exit 1
  fi

  if [ ! -n "was_time_failed" ]
  then
    echo "was_time_failed...FAIL"
  fi


  #------ Get time offsets from NTP servers ------
  query=$(ntpq -np)
  echo -e -n "$query\n"
  time_offset=$(
    echo $query |
    awk '{
    num_serv=1;
    i=12;
    while(i<=NF)
    {
      t = $(i + 3);
      reach = $(i + 6);
      if (t != "l" && t != "local" && reach != 0)
      {
        offset[num_serv] = ($(i + 8) > 0) ? $(i + 8) : 0 - $(i + 8);
        # print "time offset - ", offset[num_serv];
      num_serv++;
      }
      i+=10;
    }
    if (num_serv == 1)
      print "not available";
    else
    {
      min = offset[1];
      for (i=2; i<num_serv; i++)
      {
      if (offset[i] < min)
          min = offset[i];
      }
      printf "%.10f", min;
    }
    }'
  )

  if [ "$time_offset" != "not available" ]
  then
    time_offset=$(
    echo $time_offset |
      awk '{ print int($1); }'
    )
  fi
  offset_limit=$(
    echo $offset_limit |
    awk '{ print int($1 * 1000) }'
  )

  echo "result time offset - $time_offset"
  echo "limit time offset - $offset_limit"


  if [ "$time_offset" = "not available" ]
  then
    # Send signal about inaccessibility of NTP servers
    echo "Warnings: NTP servers are not available...Signal SS_NOTIMESRC"
    if [ -e "/usr/bin/sgtest" ]
    then
      /usr/bin/sgtest $ss_user_id $user_id $ss_notimesrc_id $ss_notimesrc_type 0
    fi

    # команда только для срабатывания - 1 раз.
    ntpd -g

    if [ -e "/usr/bin/ltime" ]
    then
      /usr/bin/ltime -c 0
    fi
  else
    # Compare result time with time limit from cfg file
    if [ "$time_offset" -le "$offset_limit" ]
    #if (("$time_offset" <= "$offset_limit"))
    #if [ `expr "$time_offset" '<=' "$offset_limit"` == 1 ]
    then
      echo "Time is OK"
      if [ "$was_time_failed" -eq 1 ]
      then
        echo "Warning: Was incorrected...Signal SS_TIMECORRECT"
        if [ -e "/usr/bin/sgtest" ]
        then
          /usr/bin/sgtest $ss_user_id $user_id $ss_time_correct_id $ss_time_correct_type 0
        fi

      # Change value for was_time_failed parameter
        sed -e "s/^was_time_failed=.*/was_time_failed=0/" -i $cfg_file
      fi

      if [ -e "/usr/bin/ltime" ]
      then
        /usr/bin/ltime -c 4
      fi

    else
      echo "Warning: Time is incorrect...Signal SS_TIMEFAILED"

      if [ -e "/usr/bin/sgtest" ]
      then
        /usr/bin/sgtest $ss_user_id $user_id $ss_time_failed_id $ss_time_failed_type $time_offset
      fi

      # команда только для срабатывания - 1 раз.
      ntpd -g

      if [ -e "/usr/bin/ltime" ]
      then
        /usr/bin/ltime -c 0
      fi

      # Change value for was_time_failed parameter
      sed -e "s/^was_time_failed=.*/was_time_failed=1/" -i $cfg_file
    fi
  fi
}

ema_time

  echo -e "Bios time = $(hwclock --show)\n"

#========================================================

#------ Current Load Average ------
# Получаем текущее значение LA
LOAD="$(uptime | grep -o 'load average.*' | cut -c 15-18)"
echo "-- Current Load Average: $LOAD "


#------ Get touch file for read-only ------
# проверяем, файл
check_touch(){
 touch_file="/var/log/ema/ntp.log"

 if test ! -f $touch_file
 then
   echo "Cannot be found the touch-file ($touch_file)"
   return -1
 fi

 query=$(touch $touch_file)
 #echo "$query"

 # шаблон сообщения
 # touch /test
 # touch: cannot touch `/test': Read-only file system
 tchmess=$( echo $query | grep -i "Read.*only" )

 # выбор сообщения
 # ID  ID_NODE ID_SCLASS ID_TYPE ID_FTR  ALIAS NAME  ID_FILEWAV
 #203  7 1 907   SS_INTEGRITY_A  Критическое нарушение целостности БДРВ  1002439
 #250  42  1 908   SS_HWFAILED Неисправность оборудования  1002456
 #256  7 1 907   SS_RESOURCEFAIL Исчерпаны системные ресурсы 1002459
 #261  43  1 907   MD_FILEPROC_ERR Ошибка работы с файлом  1002464
 #274  42  1 908   SS_SPACEWARN  Недостаточно свободного места на диске  1005748

 if [ "$tchmess" != "" ]
 then
    if [ -e "/usr/bin/sgtest" ]
    then
        echo "Warning: touch is find read-only mode  ..Signal SS_READONLY"
        /usr/bin/sgtest $ss_user_id $user_id 256 907
    fi
 fi

 return 0
}

check_touch


#------ check service file ------

# проверяем, запущена ли служба
check_service(){
  RESULT="$(ps -A|grep $1|wc -l)"
  if [[ $RESULT -eq 0 ]]; then
    echo "-- service $1 not running $RESULT= $(date +"%d.%m.%y %H:%M:%S")!"
  fi
  return $RESULT
}

# проверяем, запущена ли служба
check_service_ema(){
 #------ Config files ------
 cfg_file1="/etc/ema/ema.cfg"

 if test ! -f $cfg_file1
 then
   echo "Cannot be found the config file ($cfg_file1)"
   return -1
 fi

 strawk1=$(awk '{ if ($1!~/sleep$/) { print $1 } }' $cfg_file1 )

 for s1 in $strawk1
 do
   check_service "$s1"
 done

 return 0
}

check_service_ema










