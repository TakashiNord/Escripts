#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys, os, string, time
import binascii
import socket
import struct

addr1 = ('10.100.1.20', 2003)
addr2 = ('10.100.1.30', 2003)
addr3 = ('10.100.1.100', 2003)

def get_global_state(addr0) :
    """
    --
    """
    ret='NONE'

    # Create socket TCP/IP=SOCK_STREAM 1024  UDP=SOCK_DGRAM  2048
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM) # , socket.IPPROTO_UDP
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    try:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_RCVTIMEO, 1000)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_SNDTIMEO, 1000)
    except Exception as e:
        s.settimeout(5)
        pass

    s.connect(addr0)

    #This is needed to join a multicast group
    ip = addr0[0]
    mreq = struct.pack("4sl",socket.inet_aton(ip),socket.INADDR_ANY)

    port = addr0[1]
    try:
        s.bind(('0.0.0.0',port))
    except Exception as e:
        #print("WARNING: Failed to bind %s:%d: %s" , (ip,port,e))
        pass

    try:
        s.setsockopt(socket.IPPROTO_IP,socket.IP_ADD_MEMBERSHIP,mreq)
    except Exception as e:
        #print('WARNING: Failed to join multicast group:',e)
        pass

    fm1=fm='IIIIIII16sIhI'
    bo=sys.byteorder
    #print(bo)
    if bo=='little' : fm1='<'+ fm
    if bo=='big' : fm1='!'+ fm

    tm=int(time.time())
    #print("t=",tm)
    values = (0xf008 , 0xffff, 0xffff, 0xffff, 0xffff,0,0xfffffff,b'\0',0,0,tm)
    packer = struct.Struct(fm1)
    packed_data = packer.pack(*values)
    l1=len(packed_data)
    #print("l1=",l1)

    data = ("","")
    try:
        # Send data
        #print ('sending "%s" ' % packed_data) # binascii.hexlify(packed_data)
        s.sendall(packed_data)
        #print ('send')
        # receive data
        #while True:
        #    data = s.recvfrom(2048) # (data, addr)
        #    if not data: break
        data = s.recvfrom(2048)
        #print ('recvfrom')
    except Exception as e:
        #print('send-recvfrom =',e)
        pass
    finally:
        s.close()
    if data[0]=="" : return(ret)

    reply = data[0]
    addr = data[1]
    #print ('Server reply=' + str(reply) +'=')
    l2=len(reply)
    #print('l2(reply)=',len(reply))
    if l2==struct.calcsize('!' + fm ) :
        fm1='!' + fm
        bo='big'

    fd=struct.unpack(fm1,reply)
    #print(fd)
    v=fd[0]
    if bo=='big' :
        s=struct.pack('>I',v)
        fdt=struct.unpack('<I',s)
        #print(fdt)
        v=fdt[0]

    # 61449=master  61450=slave
    if v==61448 : ret='NONE'
    if v==61449 : ret='MASTER'
    if v==61450 : ret='SLAVE'
    return(ret)


if __name__ == '__main__':
    str=get_global_state(addr3)
    print(str)
