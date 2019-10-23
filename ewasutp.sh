#!/bin/bash

#
# 1. в файле /home/www-data/www/htdocs/WASUTP/config/wasutp.config.php строка 'replaceIp' =>....  должна быть одна. Остальные удалить, и закомментированые тоже.
# 2. строка replaceIp должна содержать поле i.host_addr, так оно подставляется в запрос "как есть".
#
#

ip1=10.51.1.50
ip2=10.51.1.55

st1=0
if ping -c 1 -W 1 $ip1 &> /dev/null
then
  st1=1
  str0="replace(replace(i.host_addr,'10.51.5.','10.51.1.'),'$ip2','$ip1')"
fi

if (($st1==0)) ; then
  str0="replace(replace(i.host_addr,'10.51.5.','10.51.1.'),'$ip1','$ip2')"
fi

fl="/home/www-data/www/htdocs/WASUTP/config/wasutp.config.php"

sed -i 's/.*replaceIp.*/    \x27replaceIp\x27 => "'$str0'",/' $fl

exit ;


