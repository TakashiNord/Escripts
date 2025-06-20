import os, sys
from datetime import datetime
import base64
import urllib2

def main() :
    s='SLAVE'
    with open('/run/ema/hoststate','r') as f
        s=f.readline()
    s=s.rstrip()
    if s=='SLAVE':
        return
    url="http://10.100.65.84:8080/rsdu/scada/api/app/info"
    u='admin'
    p='passme'
    h={'Authorization':'Basic ' + base64.b64encode('%s:%s' % (u,p) ) }
    r=urllib2.Request(url,None,h)
    try:
        res=urllib2.urlopen(r)
        d=res.read()
    except urllib2.HTTPError as error
        d=error.read()
        ou=os.popen("systemctl restart rsdu-scada-server")
        rp=ou.readlines()
        ou.close()
    tm=datetime.now()
    dtm=tm.strftime("%d.%m.%Y %H:%M:%S")
    print(dtm,s,d)


if __name__=='__main__':
    main()
    pass

#
# crontab
# */10 * * * * /usr/bin/python /root/info.py >> /root/info.log 2>&1
#
#