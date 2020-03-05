import os
import argparse
import csv
from jinja2 import Template
from string import Template


ISO_NOW = datetime.now().strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"

def print_debug(msg):
    if(debug == True):
        print("[DEBUG]\t{0}".format(msg))

def parse_args():
    parser = argparse.ArgumentParser(description='This script will generate a file based on a template and csv file')
    parser.add_argument('-v','--verbose', help='Enable verbose logging', action='store_true')
    parser.add_argument('-m', '--mapper', help='Mapper file containing mapping to be used in template', required=True, action='store')
    parser.add_argument('-d', '--mapperdelim', help='Mapper delimiter used to split data', default='|', action='store')
    parser.add_argument('-t', '--template', help='File containing the template that should be used to generate output file', required=True, action='store')
    parser.add_argument('-o', '--output', help='Output file created from mapping the template', default='output.txt', action='store')
    return parser.parse_args()

def validate_args(main_args):
    global debug
    debug = main_args.verbose
    if not os.path.isfile(main_args.template):
        raise SystemExit("Template file does not exist: {0}".format(main_args.template))
    if not os.path.isfile(main_args.mapper):
        raise SystemExit("Mapper file does not exist: {0}".format(main_args.mapper))

def parseMappingFile(mapper,delim):
    print("Begin mapping processing...")
    print("Splitting mapper using delimiter '{0}'".format(delim))

    csv.register_dialect('piper', delimiter='|', quoting=csv.QUOTE_NONE)
    # dialect='piper'
    
    with open(mapper, newline='') as csvfile:
        mapreader = csv.DictReader(csvfile, )
        for row in mapreader:
            print("Name: {} Role: {}".format(row['Name'],row['Role']))

    mappingList = None
    counter = None
    """
    # Iterate over each non-header line
    for counter,line in enumerate(mapperFile.readlines(),1):
        splitLine = line.rstrip().split(delim)
        if len(splitLine) == len(headerEles):
            mappingList.append({headerEles[headerField]:value for headerField,value in enumerate(splitLine)})
        else:
            print("Invalid record found on line {0} -> {1}".format(counter,line.rstrip()))

    {print_debug(mapping) for mapping in mappingList}
    print("Records Mapped: " + str(len(mappingList)) + "/" + str(counter))
    mapperFile.close()

    print("End mapping process...")
    """
    return mappingList,counter

def writeOutputTemplateFile(main_args):
    mappingList,mappingEleCnt = parseMappingFile(main_args.mapper,main_args.mapperdelim)

    print("\nBegin templating...")
    templateFile = open(main_args.template,"r")
    s = Template(templateFile.read())

    # Write output file using template and mapping list
    outputFile = open(main_args.output,"w")
    for i,mapping in enumerate(mappingList):
        outputFile.write(s.substitute(mapping))
        if len(mappingList) != i+1:
            outputFile.write(os.linesep) 
    outputFile.close()
    print("Records written to output file: {0}/{1}".format(str(len(mappingList))
                    ,mappingEleCnt))

    templateFile.close()
    print("End of templating...")

def main(main_args):
    validate_args(main_args)
    writeOutputTemplateFile(main_args)

"""
Execution Script
"""
if __name__ == '__main__':
    main(parse_args())