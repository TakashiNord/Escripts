#!/usr/bin/env python

import sys, os, string, time
import re
import datetime

if os.geteuid() != 0:
    sys.stderr.write("Sorry, root permission required.\n");
    sys.exit(1)

cfg_file="/etc/ema/ema_time.cfg"
#cfg_file="ema_time.cfg"

# make dictionary
EMA_VAR = {}
EMA_VAR['time_offset'] = 0.7
EMA_VAR['ss_user_id'] = 0
EMA_VAR['user_id'] = 0
EMA_VAR['ss_notimesrc_id'] = 68
EMA_VAR['ss_notimesrc_type'] = 907
EMA_VAR['ss_time_correct_id'] = 69
EMA_VAR['ss_time_correct_type'] = 909
EMA_VAR['ss_time_failed_id'] = 67
EMA_VAR['ss_time_failed_type'] = 907
EMA_VAR['was_time_failed'] = 0

# all file - cfg_file
LST = []


# ==============================
# ------ Read config file ------
# ==============================
def ema_time_load_file() :
    global EMA_VAR
    global cfg_file
    global LST
    print "Reading file ...", cfg_file
    if (not os.path.exists(cfg_file)):
        print "Cannot be found the config file = ", cfg_file
        return -1
    LST = []
    # 2.4.2 dont working
    #with open(cfg_file) as f:
    #    LST = f.read().splitlines()
    f = None
    try:
        f = open(cfg_file, 'r')
        LST = f.read().splitlines()
    finally:
        if f is not None:
            f.close()
    for s in LST:
        s=s.strip()
        s=s.lower()
        if (s.find("#")==0 or s.find("//")==0 or s.find(";")==0): continue
        t1=s.find("#")
        if (t1>0): s = s[:t1]
        t1=s.find(";")
        if (t1>0): s = s[:t1]
        t1=s.find("//")
        if (t1>0): s = s[:t1]
        s=s.strip()
        if (len(s)<=0) : continue
        t2=s.split("=")
        if (len(t2)!=2) : continue
        for v2 in EMA_VAR:
            if (v2==t2[0].strip()): EMA_VAR[v2]=t2[1].strip()
    #------ Checking parameters -------
    for key, value in EMA_VAR.items():
        #if (key=="was_time_failed"): continue
        tV=0
        if (key=="time_offset") :
            if (is_number(value)):
                tV=float(value)
            elif (value.isdigit()) :
                tV=int(value)
            else:
                tV=0.7
        else :
            if (value.isdigit()) :
                tV = int(value)
            if (tV<=0):
                if (key!="was_time_failed"):
                    print key, "...FAIL"
                    return -1
        EMA_VAR[key]=tV
    #print EMA_VAR
    return 0


def is_number(str):
    try:
        float(str)
        return True
    except ValueError:
        return False


"""
space reject
x  falsetick
.  excess
-  outlyer
+  candidat
#  selected
*  sys.peer
o  pps.peer
"""
def ema_time_ex( a ):
    if (len(a)<=2): return "not available"
    remote=""
    jitter=0
    offsetserver="none"
    offset=[]
    o=a[2:]
    for s in o:
        tl=s[0]
        l=tl.split()
        ll=len(l)
        #print "len=", ll
        remote=l[0]
        #print "remote=",remote
        if (remote.find('x')==0 or remote.find('.')==0 or remote.find('-')==0): continue
        if (remote.find('*')==0):
            offsetserver=float(l[ll-2])
            jitter=float(l[ll-1])
            #print "offsetserver=",offsetserver
        t=l[ll-7]
        reach=int(l[ll-4])
        if (t != "l" and t != "local" and reach != 0):
            offset.append(l[ll-2])
    #print offset
    if (len(offset)==0): return "not available"
    i=0
    mini = 0
    maxi = 0
    while (i<len(offset)):
        vi=abs(float(offset[i]))
        vmin=abs(float(offset[mini]))
        vmax=abs(float(offset[maxi]))
        if (vi < vmin): mini = i
        if (vi > vmax): maxi = i
        i=i+1
    vmin = min(offset)
    vmax = max(offset)
    if (offsetserver=="none"): offsetserver=float(vmax)
    if (jitter>1000000 and jitter>offsetserver): offsetserver=jitter
    ret = offsetserver
    return ret


#=========================
def ntp_status():
#=========================
    #output = subprocess.call('ps -A|grep ntp|wc -l', shell=True)
    output=os.popen("ps -A|grep ntp|wc -l")
    r = output.readlines()
    output.close()
    RESULT = r[0].strip("\n")
    if (int(RESULT)==0) :
        print "service ntp - not running"
        os.popen("service ntp stop")
        time.sleep(3)
        os.popen("service ntp start")
    else:
        output=os.popen("service ntp status")
        r = output.readlines()
        output.close()
        RESULT = r[0].strip("\n")
        # RESULT.find("unused")>=0 or RESULT.find("dead")>=0
        if (RESULT.find("dead")>=0):
            print "service ntp - is dead"
            #os.popen("service ntp restart")
            os.popen("service ntp stop")
            time.sleep(3)
            os.popen("service ntp start")
    #
    os.popen("ntpd -g")
    pass
    return 0


def ema_time():
    global EMA_VAR
    print "--"
    if (not os.path.exists("/usr/bin/sgtest")): print "Cannot be found /usr/bin/sgtest"
    if (not os.path.exists("/usr/bin/ltime")): print "Cannot be found /usr/bin/ltime"
    #------ Print current date ------
    dt=datetime.datetime.now()
    print dt
    #------ Read config file ------
    ret=ema_time_load_file()
    if (ret<0): return ret
    #------ Get time offsets from NTP servers ------
    outs=[]
    for outputstr in os.popen("ntpq -np").readlines():
        ts=outputstr.splitlines()
        print ts
        outs.append(ts)
    #print outs
    #------ Find offset ------
    time_offset = ema_time_ex(outs)
    offset_limit=EMA_VAR['time_offset']*1000
    print "result time offset - ", time_offset
    print "limit time offset - " , offset_limit
    #------ Compare offset ------
    if (time_offset=="not available"):
        # Send signal about inaccessibility of NTP servers
        print "Warnings: NTP servers are not available...Signal SS_NOTIMESRC"
        if (os.path.exists("/usr/bin/sgtest")):
            outputstr = "/usr/bin/sgtest %s %s %s %s %s " % (EMA_VAR["ss_user_id"],EMA_VAR["user_id"],EMA_VAR["ss_notimesrc_id"],EMA_VAR["ss_notimesrc_type"],"0")
            output = os.popen(outputstr)
        ntp_status()
        if (os.path.exists("/usr/bin/ltime")):
            for outputstr in os.popen("/usr/bin/ltime -c 0").readlines():
                tout= outputstr.splitlines()
                print tout[0]
    else:
        time_offset=abs(float(time_offset))
        # Compare result time with time limit from cfg file
        if (time_offset<=offset_limit):
            print "Time is OK"
            if (EMA_VAR['was_time_failed']==1):
                print "Warning: Was incorrected...Signal SS_TIMECORRECT"
                if (os.path.exists("/usr/bin/sgtest")):
                    outputstr = "/usr/bin/sgtest %s %s %s %s %s " % (EMA_VAR["ss_user_id"],EMA_VAR["user_id"],EMA_VAR["ss_time_correct_id"],EMA_VAR["ss_time_correct_type"],"0")
                    output = os.popen(outputstr)
                # Change value for was_time_failed parameter
                output = os.popen('sed -e "s/^was_time_failed=.*/was_time_failed=0/" -i ' + cfg_file)
            if (os.path.exists("/usr/bin/ltime")):
                for outputstr in os.popen("/usr/bin/ltime -c 4").readlines():
                    tout= outputstr.splitlines()
                    print tout[0]
        else:
            print "Warning: Time is incorrect...Signal SS_TIMEFAILED"
            if (os.path.exists("/usr/bin/sgtest")):
                outputstr = "/usr/bin/sgtest %s %s %s %s %s " % (EMA_VAR["ss_user_id"],EMA_VAR["user_id"],EMA_VAR["ss_time_failed_id"],EMA_VAR["ss_time_failed_type"],EMA_VAR["time_offset"])
                output = os.popen(outputstr)
            ntp_status()
            # Change value for was_time_failed parameter
            output = os.popen('sed -e "s/^was_time_failed=.*/was_time_failed=1/" -i ' + cfg_file)
            if (os.path.exists("/usr/bin/ltime")):
                for outputstr in os.popen("/usr/bin/ltime -c 0").readlines():
                    tout= outputstr.splitlines()
                    print tout[0]
    return 0


#------ Current hwclock ------
def ema_time_add1():
    #output = os.system('hwclock --show')
    output = os.popen("hwclock --show")
    r = output.readlines()
    output.close()
    RESULT = r[0].strip("\n")
    print "-- BIOS time =", RESULT
    return 0


#------ Current Load Average ------
def ema_time_add2():
    output = os.popen("uptime | grep -o 'load average.*' | cut -c 15-18")
    r = output.readlines()
    output.close()
    RESULT = r[0].strip("\n")
    print "-- Current Load Average: ", RESULT
    return RESULT


#------ check service file ------
def ema_service( serv ):
    output=os.popen("ps -A|grep " + serv + "|wc -l")
    r = output.readlines()
    output.close()
    RESULT = r[0].strip("\n")
    if (int(RESULT)==0) :
        dt=datetime.datetime.now()
        print "-- service %s not running %s=%s !" % (serv, RESULT, dt)
    return RESULT


def ema_check_service():
    #------ Config files ------
    cfg_file1="/etc/ema/ema.cfg"
    if (not os.path.exists(cfg_file1)):
        print "Cannot be found the config file " , cfg_file1
        return -1
    strawk1=[]
    f = None
    try:
        f = open(cfg_file1, 'r')
        strawk1 = f.read().splitlines()
    finally:
        if f is not None:
            f.close()
        else :
            return
    for s1 in strawk1:
        s1=s1.strip()
        s1=s1.lower()
        if (s1.find("sleep")>=0): continue
        l1=s1.split()
        ema_service(l1[0])
    return


#------ Get touch file for read-only ------
# touch /test
# touch: cannot touch `/test': Read-only file system
#
def touch(path):
    import os, time
    now = time.time()
    try:
        # assume it's there
        os.utime(path, (now, now))
        return 0
    except os.error:
        # if it isn't,
        #open(path, 'a').close()
        return 1


def check_touch():
    global EMA_VAR
    touch_file="/var/log/ema/ntp.log"
    if (not os.path.exists(touch_file)):
        print "Cannot be found the touch-file ", touch_file
        return -1
    #output = os.popen("touch " + touch_file)
    if (touch(touch_file)):
        print "Warning: touch is find read-only mode  ..Signal SS_READONLY"
        if (os.path.exists("/usr/bin/sgtest")):
            if (EMA_VAR['ss_user_id'] > 0 and EMA_VAR['user_id'] > 0):
                outputstr = "/usr/bin/sgtest %s %s %s %s " % (EMA_VAR["ss_user_id"],EMA_VAR["user_id"],"256", "907")
                output = os.popen(outputstr)
    return 0


if __name__ == '__main__':
    ema_time()
    check_touch()



