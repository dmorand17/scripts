#!/usr/bin/env python
import os
import argparse
import dicttoxml
from jsonslicer import JsonSlicer
from datetime import datetime

parser = argparse.ArgumentParser(description='This script will take an input AU json file and convert into an XML file (1 line per Authorization)')
parser.add_argument('-i', '--input', help='input AU json file', required=True, action='store')
parser.add_argument('-o', '--output', help='output xml file', required=True, action='store')
args = parser.parse_args()

if os.path.exists(args.output):
    os.remove(args.output)

def gettime():
    return datetime.now().strftime("%Y%m%d %H:%M:%S")

print("Converting {} to xml...".format(args.input))
with open(args.input) as data, open(args.output,"a+") as xmlFile:
    auths=0
    for case_level in JsonSlicer(data, ('CaseLevel', None)):
        xml = dicttoxml.dicttoxml(case_level,custom_root='CaseLevel',attr_type=False)
        xmlFile.write(xml.decode("utf-8") + "\n")
        auths+=1
        
        if auths % 5000 == 0:
            print("{}|converted {} auths...".format(gettime(),str(auths)))
    print("{}|Total Authorizations converted: {}".format(gettime(),str(auths)))

print("{} created".format(args.output))