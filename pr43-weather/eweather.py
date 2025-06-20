#!/usr/bin/python
# -*- coding: utf-8 -*-

import urllib
import urllib2
import json

VERSION = 0.1

#pip install pyodbc
#import pyodbc
driver = 'DRIVER={SQL Server}'
server = 'SERVER=localhost'
port = 'PORT=1433'
db = 'DATABASE=rsdu2'
user = 'rsduadmin'
pw = 'passme'
conn_str = ';'.join([driver, server, port, db, user, pw])

#1\We recommend making calls to the API no more than one time every 10 minutes for one location (city / coordinates / zip-code).
#This is due to the fact that weather data in our system is updated no more than one time every 10 minutes.
#2\The server name is api.openweathermap.org. Please, never use the IP address of the server.
#3\Better call API by city ID instead of a city name, city coordinates or zip code to get a precise result. The list of cities' IDs is here.
#4\Please, mind that Free and Startup accounts have limited service availability. If you do not receive a response from the API, please, wait at least for 10 min and then repeat your request. We also recommend you to store your previous request.

# Current weather data
#api.openweathermap.org/data/2.5/weather?q={city name},{country code}
#api.openweathermap.org/data/2.5/weather?id={city ID}

#5 day forecast is available at any location or city. It includes weather data every 3 hours
#API call:
#api.openweathermap.org/data/2.5/forecast?q={city name},{country code}
#api.openweathermap.org/data/2.5/forecast?id={city ID}

conf={
   "OpenWeatherMapOptions": {
    "Enabled": True,
    "URL": "http://api.openweathermap.org/data/2.5/forecast",
    "AppId": "",
    "Locations": [
      {
        "desc": "г.Хабаровск",
        "name": "Khabarovsk",
        "country": "RU",
        "RequestPeriod": 60,
        "id": 2022890,
        "Links": [
          {
            "Name": "Temp",
            "OWMParam": "main.temp",
            "ParamId": 7818591,
            "TableId": 1000522,
            "Gtopt": "GLT_ANALOG_OPT_AVGHOUR",
            "Interpolation": True
          }
        ]
      },
      {
        "desc": "г.Комсомольск-на-Амуре",
        "name": "Komsomolsk-on-Amur",
        "country": "RU",
        "RequestPeriod": 60,
        "id": 2021851,
        "Links": [
          {
            "Name": "Temp",
            "OWMParam": "main.temp",
            "ParamId": 7818611,
            "TableId": 1000522,
            "Gtopt": "GLT_ANALOG_OPT_AVGHOUR",
            "Interpolation": True
          }
        ]
      },
      {
        "desc": "г.Амурск",
        "name": "Amursk",
        "country": "RU",
        "RequestPeriod": 60,
        "id": 2027749,
        "Links": [
          {
            "Name": "Temp",
            "OWMParam": "main.temp",
            "ParamId": 7818612,
            "TableId": 1000522,
            "Gtopt": "GLT_ANALOG_OPT_AVGHOUR",
            "Interpolation": True
          }
        ]
      },
      {
        "desc": "г.Николаевск-на-Амуре",
        "name": "Nikolayevsk-na-amure",
        "country": "RU",
        "RequestPeriod": 60,
        "id": 2122850,
        "Links": [
          {
            "Name": "Temp",
            "OWMParam": "main.temp",
            "ParamId": 7818613,
            "TableId": 1000522,
            "Gtopt": "GLT_ANALOG_OPT_AVGHOUR",
            "Interpolation": True
          }
        ]
      },
      {
        "desc": "г.Биробиджан",
        "name": "Birobidzhan",
        "country": "RU",
        "RequestPeriod": 60,
        "id": 2026643,
        "Links": [
          {
            "Name": "Temp",
            "OWMParam": "main.temp",
            "ParamId": 7818614,
            "TableId": 1000522,
            "Gtopt": "GLT_ANALOG_OPT_AVGHOUR",
            "Interpolation": True
          }
        ]
      },
      {
        "desc": "п.Чегдомын",
        "name": "Chegdomyn",
        "country": "RU",
        "RequestPeriod": 60,
        "id": 2025579,
        "Links": [
          {
            "Name": "Temp",
            "OWMParam": "main.temp",
            "ParamId": 7818615,
            "TableId": 1000522,
            "Gtopt": "GLT_ANALOG_OPT_AVGHOUR",
            "Interpolation": True
          }
        ]
      },
      {
        "desc": "пгт.Майский",
        "name": "Sovetskaya Gavan",
        "country": "RU",
        "RequestPeriod": 60,
        "id": 2121052,
        "Links": [
          {
            "Name": "Temp",
            "OWMParam": "main.temp",
            "ParamId": 7818616,
            "TableId": 1000522,
            "Gtopt": "GLT_ANALOG_OPT_AVGHOUR",
            "Interpolation": True
          }
        ]
      },
      {
        "desc": "г.Владивосток",
        "name": "Vladivostok",
        "country": "RU",
        "RequestPeriod": 60,
        "id": 2013348,
        "Links": [
          {
            "Name": "Temp",
            "OWMParam": "main.temp",
            "ParamId": 7818617,
            "TableId": 1000522,
            "Gtopt": "GLT_ANALOG_OPT_AVGHOUR",
            "Interpolation": True
          }
        ]
      },
      {
        "desc": "г.Артем",
        "name": "Artem",
        "country": "RU",
        "RequestPeriod": 60,
        "id": 2027456,
        "Links": [
          {
            "Name": "Temp",
            "OWMParam": "main.temp",
            "ParamId": 7818618,
            "TableId": 1000522,
            "Gtopt": "GLT_ANALOG_OPT_AVGHOUR",
            "Interpolation": True
          }
        ]
      },
      {
        "desc": "г.Партизанск",
        "name": "Partizansk",
        "country": "RU",
        "RequestPeriod": 60,
        "id": 2018116,
        "Links": [
          {
            "Name": "Temp",
            "OWMParam": "main.temp",
            "ParamId": 7818619,
            "TableId": 1000522,
            "Gtopt": "GLT_ANALOG_OPT_AVGHOUR",
            "Interpolation": True
          }
        ]
      },
      {
        "desc": "пгт.Лучегорск",
        "name": "Luchegorsk",
        "country": "RU",
        "RequestPeriod": 60,
        "id": 2020689,
        "Links": [
          {
            "Name": "Temp",
            "OWMParam": "main.temp",
            "ParamId": 7818620,
            "TableId": 1000522,
            "Gtopt": "GLT_ANALOG_OPT_AVGHOUR",
            "Interpolation": True
          }
        ]
      },
      {
        "desc": "г.Нерюнгри",
        "name": "Neryungri",
        "country": "RU",
        "RequestPeriod": 60,
        "id": 2019309,
        "Links": [
          {
            "Name": "Temp",
            "OWMParam": "main.temp",
            "ParamId": 7818621,
            "TableId": 1000522,
            "Gtopt": "GLT_ANALOG_OPT_AVGHOUR",
            "Interpolation": True
          }
        ]
      },
      {
        "desc": "пгт.Чульман",
        "name": "Chulman",
        "country": "RU",
        "RequestPeriod": 60,
        "id": 2025261,
        "Links": [
          {
            "Name": "Temp",
            "OWMParam": "main.temp",
            "ParamId": 7818622,
            "TableId": 1000522,
            "Gtopt": "GLT_ANALOG_OPT_AVGHOUR",
            "Interpolation": True
          }
        ]
      },
      {
        "desc": "г.Благовещенск",
        "name": "Blagoveshchensk",
        "country": "RU",
        "RequestPeriod": 60,
        "id": 2026609,
        "Links": [
          {
            "Name": "Temp",
            "OWMParam": "main.temp",
            "ParamId": 7818623,
            "TableId": 1000522,
            "Gtopt": "GLT_ANALOG_OPT_AVGHOUR",
            "Interpolation": True
          }
        ]
      },
      {
        "desc": "пгт.Прогресс",
        "name": "Progress",
        "country": "RU",
        "RequestPeriod": 60,
        "id": 504977,
        "Links": [
          {
            "Name": "Temp",
            "OWMParam": "main.temp",
            "ParamId": 7818624,
            "TableId": 1000522,
            "Gtopt": "GLT_ANALOG_OPT_AVGHOUR",
            "Interpolation": True
          }
        ]
      }
    ]
  }
}


def checkKey(d, key):
    """
    """
    if (type(d)!=dict):
        return None
    if key in d.keys():
        return d[key]
    else:
        return None


def urlGet(url,args):
    """
    """
    data=None
    # Отправляем HTTP POST запрос, но нам нужен GET
    #request = urllib2.Request(url,args)
    try:
        response = urllib2.urlopen(url)
        # Ответ сервера
        if (response.code==200) :
            # Получаем ответ
            data = response.read()
            #print(data)
            # Узнаем длину страницу
            l = len(data)
    except urllib2.URLError, e:
        #print e.reason
        pass
    except Exception:
        pass
    return(data)


def OpenWeatherMap() :
    """
    """
    flag=conf["OpenWeatherMapOptions"]["Enabled"]
    if flag==False :
        print("OpenWeatherMap -> Disable")
        return(0)
    cities=conf["OpenWeatherMapOptions"]["Locations"]
    url=conf["OpenWeatherMapOptions"]["URL"]
    appid=conf["OpenWeatherMapOptions"]["AppId"]
    for ii in range(len(cities)):
        town=cities[ii]
        desc=town["desc"]
        name=town["name"]
        country=town["country"]
        repe=town["RequestPeriod"]
        id=town["id"]
        # разные способы контактекции запроса
        # if id
        #param="id="+str(id)+'&APPID='+appid+"&units=metric"
        # if name
        #param="q="+name+","+country+'&APPID='+appid+"&units=metric"
        nm=name+","+country
        param = { "q":nm, "units":"metric","APPID" :appid }
        #param = { "id":id, "units":"metric","APPID" :appid }
        encoded_args = urllib.urlencode(param)
        # url?
        urlall = url + "?" + encoded_args
        print(urlall)
        dt=urlGet(urlall, encoded_args)
        if (dt==None) :
            continue
        js = json.loads(dt)
        cnt=checkKey(js,"cnt")
        # if weather
        if (cnt==None) :
            cid=js["id"]
            cname=js["name"]
            ctimezone=js["timezone"]
            print("id=",cid, " name=",cname," timezone=",ctimezone)
            dt=js["dt"]
            temp=js["main"]["temp"]
            print("    dt=",dt,"    temp=",temp)
        else :
            # if forecast
            si=int(cnt)
            li=js["list"]
            cid=js["city"]["id"]
            cname=js["city"]["name"]
            ctimezone=js["city"]["timezone"]
            print("id=",cid, " name=",cname," timezone=",ctimezone)
            for jj in range(len(li)):
                l=li[jj]
                dt=l["dt"]
                temp=l["main"]["temp"]
                dt_txt=l["dt_txt"]
                print("    dt=",dt,"  dt_txt=",dt_txt," temp=",temp)
        #if ii==0 : break
        pass
    pass
    return(0)


def main() :
    OpenWeatherMap()
    pass
    return(0)


if __name__ == '__main__':
    main()
