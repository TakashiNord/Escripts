# -*- coding: utf-8 -*-
import xml.dom.minidom as md
#import urllib.request
import sys

reload(sys)
sys.setdefaultencoding('utf8')

def Iec() :
    return 0 ;
	
def Ldefice() :
    return ;

	


def getNodeText(node):
    nodelist = node.childNodes
    if nodelist=="" : return ''
    result = []
    for node in nodelist:
        if node.nodeType == node.TEXT_NODE:
            result.append(node.data)
    return ''.join(result)

def print_node(root):
    if root.childNodes:
        for node in root.childNodes:
            if node.nodeType == node.ELEMENT_NODE:
                print node.tagName,"has value:", node.nodeValue, "and is child of:", node.parentNode.tagName
                print('Элемент: %s' % node.nodeName)
                for (name, value) in node.attributes.items():
                    print(' Attr -- имя: %s значение: %s' % (name, value))
                print(' v = %s' % getNodeText(node))
            print_node(node)

def P():
    dom = md.parse("example.cid")
    root = dom.documentElement
    print_node(root)


if __name__ == "__main__":
    P()

