#!/bin/bash
export PATH="/usr/local/bin:/usr/bin:/usr/X11R6/bin:/bin:/usr/lib/mit/bin:/usr/lib/mit/sbin:/opt/oracle/product/10g/bin"

LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH

ipaddr=192.168.10.71
# Node
s0=1
echo "s=$s0"
# date
s1=$(date  +%s)
echo "s=$s1"
# UPS status
s2=`snmpget -Oqv -c public -v 2c $ipaddr .1.3.6.1.4.1.318.1.1.1.2.1.1.0`
echo "s=$s2"
# charge level,%
s3=$(snmpget -Oqv -c public -v 2c $ipaddr .1.3.6.1.4.1.318.1.1.1.2.3.1.0)
echo "s=$s3"
# Time on battery
s4=$(snmpget -Oqvt -c public -v 2c $ipaddr .1.3.6.1.4.1.318.1.1.1.2.1.2.0)
echo "s=$s4"
# temperature,degree
s5=$(snmpget -Oqv -c public -v 2c $ipaddr .1.3.6.1.4.1.318.1.1.1.2.3.2.0)
echo "s=$s5"
# input voltage,V
s6=`snmpget -Oqv -c public -v 2c $ipaddr .1.3.6.1.4.1.318.1.1.1.3.3.1.0`
echo "s=$s6"
# output voltage,V
s7=`snmpget -Oqv -c public -v 2c $ipaddr .1.3.6.1.4.1.318.1.1.1.4.3.1.0`
echo "s=$s7"

 export ORACLE_BASE=/opt/oracle
 export ORACLE_HOME=$ORACLE_BASE/product/10g
 export ORACLE_SID=rsdu
 export ORA_NLS10=$ORACLE_HOME/nls/data
 export TNS_ADMIN=/opt/oracle/product/10g/network/admin
 LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$ORACLE_HOME/lib
 export LD_LIBRARY_PATH


sqlplus /nolog<<EOF
connect rsduadmin/passme
insert into APC_POWER_LOG(id,node,time1970,status,capacity,time,t,inputvol,outputvol) 
select max(APC_POWER_LOG.id)+1,$s0,$s1,$s2,$s3,$s4,$s5,$s6,$s7 from APC_POWER_LOG;
commit;
exit
EOF

