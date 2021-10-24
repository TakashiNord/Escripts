#!/usr/bin/env python

"""xml2json.py  Convert XML to JSON

Relies on ElementTree for the XML parsing.  This is based on
pesterfish.py but uses a different XML->JSON mapping.
The XML->JSON mapping is described at
http://www.xml.com/pub/a/2006/05/31/converting-between-xml-and-json.html

Rewritten to a command line utility by Hay Kranen < github.com/hay > with
contributions from George Hamilton (gmh04) and Dan Brown (jdanbrown)

XML                              JSON
<e/>                             "e": null
<e>text</e>                      "e": "text"
<e name="value" />               "e": { "@name": "value" }
<e name="value">text</e>         "e": { "@name": "value", "#text": "text" }
<e> <a>text</a ><b>text</b> </e> "e": { "a": "text", "b": "text" }
<e> <a>text</a> <a>text</a> </e> "e": { "a": ["text", "text"] }
<e> text <a>text</a> </e>        "e": { "#text": "text", "a": "text" }

This is very similar to the mapping used for Yahoo Web Services
(http://developer.yahoo.com/common/json.html#xml).

This is a mess in that it is so unpredictable -- it requires lots of testing
(e.g. to see if values are lists or strings or dictionaries).  For use
in Python this could be vastly cleaner.  Think about whether the internal
form can be more self-consistent while maintaining good external
characteristics for the JSON.

Look at the Yahoo version closely to see how it works.  Maybe can adopt
that completely if it makes more sense...

R. White, 2006 November 6
"""

import json
import optparse
import sys
import os
from collections import OrderedDict

import xml.etree.cElementTree as ET


def strip_tag(tag):
    strip_ns_tag = tag
    split_array = tag.split('}')
    if len(split_array) > 1:
        strip_ns_tag = split_array[1]
        tag = strip_ns_tag
    return tag


def elem_to_internal(elem, strip_ns=1, strip=1):
    """Convert an Element into an internal dictionary (not JSON!)."""

    d = OrderedDict()
    elem_tag = elem.tag
    if strip_ns:
        elem_tag = strip_tag(elem.tag)
    for key, value in list(elem.attrib.items()):
        d['' + key] = value

    # loop over subelements to merge them
    for subelem in elem:
        v = elem_to_internal(subelem, strip_ns=strip_ns, strip=strip)

        tag = subelem.tag
        if strip_ns:
            tag = strip_tag(subelem.tag)

        value = v[tag]

        try:
            # add to existing list for this tag
            d[tag].append(value)
        except AttributeError:
            # turn existing entry into a list
            d[tag] = [d[tag], value]
        except KeyError:
            # add a new non-list entry
            d[tag] = value
    text = elem.text
    tail = elem.tail
    if strip:
        # ignore leading and trailing whitespace
        if text:
            text = text.strip()
        if tail:
            tail = tail.strip()

    if tail:
        d['#tail'] = tail

    if d:
        # use #text element if other attributes exist
        if text:
            d["#text"] = text
    else:
        # text is the value if no attributes
        d = text or None
    return {elem_tag: d}


def elem2json(elem, options, strip_ns=1, strip=1):

    """Convert an ElementTree or Element into a JSON string."""

    if hasattr(elem, 'getroot'):
        elem = elem.getroot()
    pretty=1
    if pretty:
        return json.dumps(elem_to_internal(elem, strip_ns=strip_ns, strip=strip), indent=2)
    else:
        return json.dumps(elem_to_internal(elem, strip_ns=strip_ns, strip=strip))


def xml2json(xmlstring, options, strip_ns=1, strip=1):

    """Convert an XML string into a JSON string."""

    elem = ET.fromstring(xmlstring)
    return elem2json(elem, options, strip_ns=strip_ns, strip=strip)


def main():
    #options=[]
    #options={"out":"","strip_text":"0","pretty":"0","strip_ns":"1","strip_nl":"1"}
    options=("","0","0","1","1")

    inputstream = open("e:\\pr38-cid2profile\\cid2profile\\example.cid",encoding ="utf8")
    input = inputstream.read()

    strip = 0
    strip_ns = 0
    strip_nl=0


    if strip_nl:
        input = input.replace('\n', '').replace('\r','')
    out = xml2json(input, options, 1, 1)

    #if (options.out):
    file = open("e:\\pr38-cid2profile\\t.json", 'w')
    file.write(out)
    file.close()
    #else:
    #    print(out)

if __name__ == "__main__":
    main()

