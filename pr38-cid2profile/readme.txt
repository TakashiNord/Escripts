
pr38-cid2profile

проект не завершен. потеря интереса.


============================================================================

https://rtfm.co.ua/python-rabota-s-xml-fajlami-i-modul-xml-etree-elementtree/

http://simplejson.github.io/simplejson/

https://python-scripts.com/xml-python


import json

x = {
"name": "Viktor",
"age": 30,
"married": True,
"divorced": False,
"children": ("Anna","Bogdan"),
"pets": None,
"cars": [
{"model": "BMW 230", "mpg":  27.5},
{"model": "Ford Edge", "mpg": 24.1}  
]
}
print(json.dumps(x))


Если в данных Python есть символы кириллицы, метод json.dumps() преобразует их с кодировкой по умолчанию. 
Что бы сохранить кириллицу используйте параметр ensure_ascii=False

import json

x = {
"name": "Виктор"
}
y = {
"name": "Виктор"
}
print(json.dumps(x))
print(json.dumps(y, ensure_ascii=False))



https://codebeautify.org/jsontoxml
https://codebeautify.org/xmltojson
