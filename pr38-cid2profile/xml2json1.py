#!/usr/bin/env python

import json
import optparse
import sys
import os
from collections import OrderedDict

import xml.etree.cElementTree as ET

xRoot = {
    "depends": {
        "da_proto_desc": ["150", "151", "152", "154", "156", "153", "155", "157", "158", "159"],
        "sys_dtyp": ["252", "456", "457", "405", "406"],
        "sys_gtopt": ["1", "8", "38"]
    },
    "hash": None,
    "info": {
        "creation_time": None,
        "device_name": None,
        "host": None,
        "is_route": 0
    },
    "tree": [
    ]
}


def jsonData(name, id_type, cvalif, id_gtopt, id_proto_point, attr_name ):
    ''' обязательны name и id_type '''
    xData = {
        "data": {
        "attr_name": None,
        "color": None,
        "cvalif": None,
        "id": None,
        "id_dev": None,
        "id_gtopt": None,
        "id_parent": None,
        "id_proto_point": None,
        "id_type": None,
        "name": None,
        "scale": None
        }
    }
    xData["attr_name"]= attr_name #? (std::string)"\"" + attr_name + "\", " : "null, ";
    xData["cvalif"]=cvalif #>= 0 ? "\"" + std::to_string(cvalif) + "\", " : "null, ";
    xData["id_gtopt"]=id_gtopt #>= 0 ? "\"" + std::to_string(id_gtopt) + "\", " : "null, ";
    xData["id_proto_point"]=id_proto_point #>= 0 ? "\"" + std::to_string(id_proto_point) + "\", " : "null, ";
    xData["id_type"]=id_type or None

    #экранируем кавычки в имени " - &quot; " = \\\"
    #name=name.replace("\"", "\\\") 

    #ограничения от пхпэшника     < - &lt;    > - &gt;
    name=name.replace("<", " ")
    name=name.replace(">", " ")
    xData["name"]=name

    return xData


def checkKey(d, key):    
    if (type(d)!=dict):
        return None
    if key in d.keys(): 
        return d[key]
    else: 
        return None


def m1():
    """  """
    # load file
    #
    js = {}
    json_file_path = "E:\\pr38-cid2profile\\t2.json"
    with open(json_file_path, 'r') as j:
        js = json.loads(j.read())
    nm=js["SCL"]["IED"]["name"]
    jip=js["SCL"]["Communication"]["SubNetwork"]["ConnectedAP"]["Address"]["P"]
    ip=None
    port=102
    for i in range(len(jip)):
        if (checkKey(jip[i],"type")=="IP"): ip=checkKey(jip[i],"#text")
        if (checkKey(jip[i],"type")=="MMS-Port"): port=checkKey(jip[i],"#text")
    print(ip,port)
    LNodeType=js["SCL"]["DataTypeTemplates"]["LNodeType"]
    #print(LNodeType)
    DOType=js["SCL"]["DataTypeTemplates"]["DOType"]
    #print(DOType)
    DAType=js["SCL"]["DataTypeTemplates"]["DAType"]
    #print(DAType)
    LDevice=js["SCL"]["IED"]["AccessPoint"]["Server"]["LDevice"]
    #print(LDevice)
    print('---------------')
    if (type(LDevice)==list): lenLD=len(LDevice)
    if (type(LDevice)==dict): lenLD=1
    for ii in range(lenLD):
        if (type(LDevice)==list): LD=LDevice[ii]
        if (type(LDevice)==dict): LD=LDevice
        LD["LN"].insert(0,LD["LN0"])
        del LD["LN0"]
        #LD["LN"].pop(0)
        inst=checkKey(LD,'inst')
        desc=checkKey(LD,'desc')
        print('-- ' ,inst, ' ' , desc)
        LN=LD["LN"]
        #print(type(LN))
        ld={}
        for i in range(len(LN)):
            lni=LN[i]
            lndesc=checkKey(lni,'desc')
            lnType=checkKey(lni,'lnType')
            lnClass=checkKey(lni,"lnClass")
            lninst=checkKey(lni,"inst")
            print(lndesc, ' ' , lnType , ' ', lnClass , ' ', lninst)
            ReportControl=checkKey(lni,"ReportControl")
            DataSet=checkKey(lni,"DataSet")
            if ReportControl!=None :
                # формируем список
                for j in range(len(ReportControl)):
                    rp=ReportControl[j]
                    rpname=checkKey(rp,"name")
                    rptID=checkKey(rp,"rptID") # "ENIP2BAYCTRL/LLN0$RP$urcbMX01"
                    rpdatSet=checkKey(rp,"datSet")
                    tmplr=rptID.split('$');
                    ldn=rpname;
                    if len(tmplr)==3 : ldn=tmplr[2];
                    for k in range(len(DataSet)):
                        ds=DataSet[k]
                        dsname=checkKey(ds,"name")
                        if (dsname==rpdatSet) :
                            fcda=checkKey(ds,"FCDA")
                            for z in fcda :
                                print(z)
                                pass   
                            break
                        pass
            pass
    print('---------------')
    pass
    return 0


def main():
    m1()
    pass
    return

if __name__ == "__main__":
    main()

